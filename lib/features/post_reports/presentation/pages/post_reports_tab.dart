import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_report_entities.dart';
import '../../domain/entities/post_reports_query.dart';
import '../bloc/post_reports_bloc.dart';
import '../widgets/post_report_thumbnail.dart';

class PostReportsTab extends StatefulWidget {
  const PostReportsTab({
    super.key,
    this.denseLayout = false,
    required this.onRowTap,
  });

  final bool denseLayout;
  final ValueChanged<PostReportListItem> onRowTap;

  @override
  State<PostReportsTab> createState() => _PostReportsTabState();
}

class _PostReportsTabState extends State<PostReportsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _applyCategoryFilter(
    BuildContext context,
    PostReportsLoaded state,
    _PostReportCategoryFilter filter,
  ) {
    final next = switch (filter) {
      _PostReportCategoryFilter.all => state.query.copyWith(
          clearIsAd: true,
          clearIsStory: true,
          clearIsAuctionable: true,
        ),
      _PostReportCategoryFilter.auction => state.query.copyWith(
          isAuctionable: true,
          clearIsAd: true,
          clearIsStory: true,
        ),
      _PostReportCategoryFilter.stories => state.query.copyWith(
          isStory: true,
          clearIsAd: true,
          clearIsAuctionable: true,
        ),
      _PostReportCategoryFilter.ads => state.query.copyWith(
          isAd: true,
          clearIsStory: true,
          clearIsAuctionable: true,
        ),
    };
    context.read<PostReportsBloc>().add(UpdatePostReportsFiltersEvent(next));
  }

  _PostReportCategoryFilter _selectedCategory(PostReportsListQuery query) {
    if (query.isAuctionable == true) return _PostReportCategoryFilter.auction;
    if (query.isStory == true) return _PostReportCategoryFilter.stories;
    if (query.isAd == true) return _PostReportCategoryFilter.ads;
    return _PostReportCategoryFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PostReportsBloc, PostReportsState>(
      builder: (context, state) {
        if (state is PostReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PostReportsError) {
          return _ErrorBody(
            message: state.message,
            onRetry: () => context
                .read<PostReportsBloc>()
                .add(LoadPostReportsEvent(refresh: true)),
          );
        }
        if (state is! PostReportsLoaded) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.denseLayout ? 0 : 12,
            widget.denseLayout ? 0 : 8,
            widget.denseLayout ? 0 : 12,
            widget.denseLayout ? 0 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FiltersBar(
                loaded: state,
                dense: widget.denseLayout,
                selectedCategory: _selectedCategory(state.query),
                onCategorySelected: (filter) =>
                    _applyCategoryFilter(context, state, filter),
              ),
              if (state.isFetching)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: state.posts.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.t('no_results'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _PostsTable(
                      posts: state.posts,
                      onRowTap: widget.onRowTap,
                    ),
            ),
            _PaginationBar(loaded: state),
            ],
          ),
        );
      },
    );
  }
}

enum _PostReportCategoryFilter { all, auction, stories, ads }

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.loaded,
    required this.dense,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final PostReportsLoaded loaded;
  final bool dense;
  final _PostReportCategoryFilter selectedCategory;
  final ValueChanged<_PostReportCategoryFilter> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pad = dense ? 8.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, dense ? 6 : 12, pad, dense ? 4 : 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final filter in _PostReportCategoryFilter.values)
            _CategoryChip(
              label: switch (filter) {
                _PostReportCategoryFilter.all =>
                  l10n.t('postFilterAuctionAll'),
                _PostReportCategoryFilter.auction =>
                  l10n.t('postFilterAuctionOnly'),
                _PostReportCategoryFilter.stories =>
                  l10n.t('postFilterStoriesOnly'),
                _PostReportCategoryFilter.ads => l10n.t('postFilterAdsOnly'),
              },
              selected: selectedCategory == filter,
              onTap: () => onCategorySelected(filter),
            ),
          Text(
            context
                .trOr('postReportPostsCount', '{count} posts')
                .replaceAll('{count}', '${loaded.total}'),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerLow,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PostsTable extends StatelessWidget {
  const _PostsTable({
    required this.posts,
    required this.onRowTap,
  });

  final List<PostReportListItem> posts;
  final ValueChanged<PostReportListItem> onRowTap;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: posts.length,
      separatorBuilder: (_, __) => Divider(color: scheme.outlineVariant, height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRowTap(post),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  PostReportThumbnail(
                    post: post,
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.description?.trim().isNotEmpty == true
                              ? post.description!.trim()
                              : '(No description)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${post.user?.username ?? post.userId} · ${post.type} · ${post.status}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MetricChip(icon: Icons.visibility_outlined, value: post.viewCount),
                  const SizedBox(width: 8),
                  _MetricChip(icon: Icons.favorite_border_rounded, value: post.likeCount),
                  const SizedBox(width: 8),
                  _MetricChip(icon: Icons.chat_bubble_outline_rounded, value: post.commentCount),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: Text(
                      _dateFormat.format(post.createdAt),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.loaded});

  final PostReportsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    if (loaded.lastPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: loaded.currentPage > 1
                ? () => context
                    .read<PostReportsBloc>()
                    .add(GoToPostReportsPageEvent(loaded.currentPage - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page ${loaded.currentPage} of ${loaded.lastPage}'),
          IconButton(
            onPressed: loaded.currentPage < loaded.lastPage
                ? () => context
                    .read<PostReportsBloc>()
                    .add(GoToPostReportsPageEvent(loaded.currentPage + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.t('retry')),
          ),
        ],
      ),
    );
  }
}
