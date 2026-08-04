import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_date_grouping.dart';
import '../utils/posts_grouped_cache.dart';
import '../utils/posts_responsive.dart';
import 'posts_group_header.dart';
import 'posts_pagination_indicators.dart';
import 'posts_table_view.dart';
import 'selectable_post_card_wrapper.dart';

class PostsListView extends StatefulWidget {
  const PostsListView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onPostTap,
    this.useInfiniteScroll = true,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;
  final bool useInfiniteScroll;

  @override
  State<PostsListView> createState() => _PostsListViewState();
}

class _PostsListViewState extends State<PostsListView> {
  final _groupCache = PostsGroupedCache();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = _groupCache.resolve(widget.state.posts);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = PostsLayoutMetrics(
          getPostsDeviceType(constraints.maxWidth),
        );

        return PostsDataListCard(
          metrics: metrics,
          count: widget.state.posts.length,
          countLabel: l10n.t('posts'),
          child: metrics.useCompactTable
              ? _PostsCompactScrollList(
                  groups: groups,
                  state: widget.state,
                  metrics: metrics,
                  scrollController: widget.scrollController,
                  onPostTap: widget.onPostTap,
                  useInfiniteScroll: widget.useInfiniteScroll,
                )
              : _PostsDesktopTableList(
                  groups: groups,
                  state: widget.state,
                  metrics: metrics,
                  scrollController: widget.scrollController,
                  onPostTap: widget.onPostTap,
                  useInfiniteScroll: widget.useInfiniteScroll,
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
    required this.groups,
    required this.state,
    required this.metrics,
    required this.scrollController,
    required this.onPostTap,
    required this.useInfiniteScroll,
  });

  final List<PostsDateGroup> groups;
  final PostsLoaded state;
  final PostsLayoutMetrics metrics;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;
  final bool useInfiniteScroll;

  @override
  Widget build(BuildContext context) {
    final posts = state.posts;

    return CustomScrollView(
      controller: scrollController,
      physics: metrics.listScrollPhysics,
      slivers: [
        for (var g = 0; g < groups.length; g++) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.cardPadding - 4,
              g == 0 ? 0 : 0,
              metrics.cardPadding - 4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: PostsDateGroupHeader(
                group: groups[g],
                isFirst: g == 0,
                metrics: metrics,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: metrics.cardPadding - 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = groups[g].posts[index];
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
                },
                childCount: groups[g].posts.length,
              ),
            ),
          ),
        ],
        if (useInfiniteScroll && state.isLoadingMore)
          const SliverToBoxAdapter(child: PostsLoadMoreIndicator()),
        if (useInfiniteScroll && state.hasReachedMax && posts.isNotEmpty)
          SliverToBoxAdapter(child: PostsEndOfListLabel()),
        SliverToBoxAdapter(child: SizedBox(height: metrics.cardPadding)),
      ],
    );
  }
}

class _PostsDesktopTableList extends StatelessWidget {
  const _PostsDesktopTableList({
    required this.groups,
    required this.state,
    required this.metrics,
    required this.scrollController,
    required this.onPostTap,
    required this.useInfiniteScroll,
  });

  final List<PostsDateGroup> groups;
  final PostsLoaded state;
  final PostsLayoutMetrics metrics;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;
  final bool useInfiniteScroll;

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
              for (var g = 0; g < groups.length; g++) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.cardPadding,
                      g == 0 ? 8 : 0,
                      metrics.cardPadding,
                      0,
                    ),
                    child: PostsDateGroupHeader(
                      group: groups[g],
                      isFirst: g == 0,
                      metrics: metrics,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = groups[g].posts[index];
                      final isLastInGroup =
                          index == groups[g].posts.length - 1;
                      final isLastGroup = g == groups.length - 1;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: isLastInGroup && isLastGroup
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
                    childCount: groups[g].posts.length,
                  ),
                ),
              ],
              if (useInfiniteScroll && state.isLoadingMore)
                const SliverToBoxAdapter(child: PostsLoadMoreIndicator()),
              if (useInfiniteScroll &&
                  state.hasReachedMax &&
                  posts.isNotEmpty)
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
