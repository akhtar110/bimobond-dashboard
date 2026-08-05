import 'package:flutter/material.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_card_layout.dart';
import '../utils/posts_date_grouping.dart';
import '../utils/posts_page_layout.dart';
import '../utils/posts_responsive.dart';
import 'posts_group_header.dart';
import 'posts_pagination_indicators.dart';
import 'selectable_post_card_wrapper.dart';

/// One responsive grid row of [SelectablePostCard] widgets.
class PostsGridRow extends StatelessWidget {
  const PostsGridRow({
    super.key,
    required this.rowPosts,
    required this.columns,
    required this.gap,
    required this.cardMetrics,
    required this.state,
    required this.onPostTap,
  });

  final List<ManagedPostEntity> rowPosts;
  final int columns;
  final double gap;
  final PostCardMetrics cardMetrics;
  final PostsLoaded state;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      final post = rowPosts.first;
      return SelectablePostCard(
        post: post,
        metrics: cardMetrics,
        isSelected: state.selectedPostIds.contains(post.id),
        onSelectionChanged: (selected) => togglePostSelection(
          context,
          post.id,
          selected ?? false,
        ),
        onTap: () => onPostTap(post),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: i < rowPosts.length
                ? RepaintBoundary(
                    child: SelectablePostCard(
                      post: rowPosts[i],
                      metrics: cardMetrics,
                      isSelected:
                          state.selectedPostIds.contains(rowPosts[i].id),
                      onSelectionChanged: (selected) => togglePostSelection(
                        context,
                        rowPosts[i].id,
                        selected ?? false,
                      ),
                      onTap: () => onPostTap(rowPosts[i]),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// Builds grid rows for a single [PostsDateGroup].
class PostsGroupGridSection extends StatelessWidget {
  const PostsGroupGridSection({
    super.key,
    required this.posts,
    required this.columns,
    required this.gap,
    required this.cardMetrics,
    required this.state,
    required this.onPostTap,
    this.isLastGroup = false,
  });

  final List<ManagedPostEntity> posts;
  final int columns;
  final double gap;
  final PostCardMetrics cardMetrics;
  final PostsLoaded state;
  final void Function(ManagedPostEntity) onPostTap;
  final bool isLastGroup;

  @override
  Widget build(BuildContext context) {
    final rowCount = (posts.length / columns).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var rowIndex = 0; rowIndex < rowCount; rowIndex++)
          Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex < rowCount - 1 || !isLastGroup ? gap : 0,
            ),
            child: PostsGridRow(
              rowPosts: posts.sublist(
                rowIndex * columns,
                _rowEnd(rowIndex, columns, posts.length),
              ),
              columns: columns,
              gap: gap,
              cardMetrics: cardMetrics,
              state: state,
              onPostTap: onPostTap,
            ),
          ),
      ],
    );
  }
}

int _rowEnd(int rowIndex, int columns, int length) {
  final end = (rowIndex + 1) * columns;
  return end > length ? length : end;
}

/// Date-grouped posts grid inside a [CustomScrollView].
class GroupedPostsGrid extends StatelessWidget {
  const GroupedPostsGrid({
    super.key,
    required this.groups,
    required this.state,
    required this.scrollController,
    required this.onPostTap,
    required this.useInfiniteScroll,
    required this.viewportWidth,
  });

  final List<PostsDateGroup> groups;
  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;
  final bool useInfiniteScroll;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final deviceType = getPostsDeviceType(viewportWidth);
    final layoutMetrics = PostsLayoutMetrics(deviceType);
    final gap = layoutMetrics.isMobile ? 8.0 : 12.0;
    final columns = postsGridColumnCount(viewportWidth);
    final cardMetrics = PostCardMetrics.fromViewport(
      viewportWidth: viewportWidth,
      gap: gap,
    );

    return CustomScrollView(
      controller: scrollController,
      cacheExtent: layoutMetrics.isMobile ? 480 : 600,
      physics: layoutMetrics.listScrollPhysics,
      slivers: [
        for (var i = 0; i < groups.length; i++) ...[
          SliverToBoxAdapter(
            child: PostsDateGroupHeader(
              group: groups[i],
              isFirst: i == 0,
              metrics: layoutMetrics,
            ),
          ),
          SliverToBoxAdapter(
            child: PostsGroupGridSection(
              posts: groups[i].posts,
              columns: columns,
              gap: gap,
              cardMetrics: cardMetrics,
              state: state,
              onPostTap: onPostTap,
              isLastGroup: i == groups.length - 1,
            ),
          ),
        ],
        if (useInfiniteScroll && state.isLoadingMore)
          const SliverToBoxAdapter(child: PostsLoadMoreIndicator()),
        if (useInfiniteScroll && state.hasReachedMax && state.posts.isNotEmpty)
          SliverToBoxAdapter(child: PostsEndOfListLabel()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}
