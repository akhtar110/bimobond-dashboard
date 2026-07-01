import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_responsive.dart';
import 'posts_pagination_indicators.dart';
import 'posts_table_view.dart';
import 'selectable_post_card_wrapper.dart';

class PostsListView extends StatelessWidget {
  const PostsListView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final posts = state.posts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = PostsLayoutMetrics(
          getPostsDeviceType(constraints.maxWidth),
        );

        return PostsDataListCard(
          metrics: metrics,
          count: posts.length,
          countLabel: l10n.t('posts'),
          child: metrics.useCompactTable
              ? _PostsCompactScrollList(
                  state: state,
                  metrics: metrics,
                  scrollController: scrollController,
                  onPostTap: onPostTap,
                )
              : _PostsDesktopTableList(
                  state: state,
                  metrics: metrics,
                  scrollController: scrollController,
                  onPostTap: onPostTap,
                ),
        );
      },
    );
  }
}

class PostsDataListCard extends StatelessWidget {
  const PostsDataListCard({
    super.key,
    required this.metrics,
    required this.count,
    required this.countLabel,
    required this.child,
  });

  final PostsLayoutMetrics metrics;
  final int count;
  final String countLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.cardPadding,
                metrics.cardPadding - 4,
                metrics.cardPadding,
                8,
              ),
              child: Text(
                '$count $countLabel',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _PostsCompactScrollList extends StatelessWidget {
  const _PostsCompactScrollList({
    required this.state,
    required this.metrics,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final PostsLayoutMetrics metrics;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final posts = state.posts;
    final itemCount = posts.length +
        (state.isLoadingMore ? 1 : 0) +
        (state.hasReachedMax && posts.isNotEmpty ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      physics: metrics.listScrollPhysics,
      padding: EdgeInsets.fromLTRB(
        metrics.cardPadding - 4,
        0,
        metrics.cardPadding - 4,
        metrics.cardPadding,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < posts.length) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PostsCompactCard(
              post: post,
              isSelected: state.selectedPostIds.contains(post.id),
              onSelectionChanged: (selected) => togglePostSelection(
                context,
                post.id,
                selected ?? false,
              ),
              onTap: () => onPostTap(post),
            ),
          );
        }
        if (state.isLoadingMore) return const PostsLoadMoreIndicator();
        return PostsEndOfListLabel();
      },
    );
  }
}

class _PostsDesktopTableList extends StatelessWidget {
  const _PostsDesktopTableList({
    required this.state,
    required this.metrics,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final PostsLayoutMetrics metrics;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final posts = state.posts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = postsTableDensityForWidth(constraints.maxWidth);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: metrics.listScrollPhysics,
            cacheExtent: 600,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: PostsTableHeaderDelegate(
                  l10n: l10n,
                  scheme: scheme,
                  density: density,
                  allVisibleSelected: state.allVisibleSelected,
                  someVisibleSelected: state.someVisibleSelected,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    final isLast = index == posts.length - 1;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                      ),
                      child: PostsTableRow(
                        post: post,
                        density: density,
                        striped: index.isOdd,
                        isSelected:
                            state.selectedPostIds.contains(post.id),
                        onSelectionChanged: (selected) =>
                            togglePostSelection(
                          context,
                          post.id,
                          selected ?? false,
                        ),
                        onTap: () => onPostTap(post),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(child: PostsLoadMoreIndicator()),
              if (state.hasReachedMax && posts.isNotEmpty)
                SliverToBoxAdapter(child: PostsEndOfListLabel()),
              SliverToBoxAdapter(
                child: SizedBox(height: metrics.cardPadding),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PostsTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  PostsTableHeaderDelegate({
    required this.l10n,
    required this.scheme,
    required this.density,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final PostsTableDensity density;
  final bool allVisibleSelected;
  final bool someVisibleSelected;

  @override
  double get minExtent => kPostsTableHeaderHeight;

  @override
  double get maxExtent => kPostsTableHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: PostsTableHeader(
        l10n: l10n,
        density: density,
        allVisibleSelected: allVisibleSelected,
        someVisibleSelected: someVisibleSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PostsTableHeaderDelegate oldDelegate) {
    return oldDelegate.allVisibleSelected != allVisibleSelected ||
        oldDelegate.someVisibleSelected != someVisibleSelected ||
        oldDelegate.density != density;
  }
}
