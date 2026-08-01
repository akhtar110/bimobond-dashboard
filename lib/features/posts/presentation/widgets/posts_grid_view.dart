import 'package:flutter/material.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_card_layout.dart';
import '../utils/posts_page_layout.dart';
import '../utils/posts_responsive.dart';
import 'posts_pagination_indicators.dart';
import 'selectable_post_card_wrapper.dart';

class PostsGridView extends StatelessWidget {
  const PostsGridView({
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
  Widget build(BuildContext context) {
    final posts = state.posts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final deviceType = getPostsDeviceType(viewportWidth);
        final layoutMetrics = PostsLayoutMetrics(deviceType);
        final gap = layoutMetrics.isMobile ? 8.0 : 12.0;
        final columns = postsGridColumnCount(viewportWidth);
        final rowCount = (posts.length / columns).ceil();
        final cardMetrics = PostCardMetrics.fromViewport(
          viewportWidth: viewportWidth,
          gap: gap,
        );

        return CustomScrollView(
          controller: scrollController,
          cacheExtent: layoutMetrics.isMobile ? 480 : 600,
          physics: layoutMetrics.listScrollPhysics,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, rowIndex) {
                  final start = rowIndex * columns;
                  final end = (start + columns).clamp(0, posts.length);
                  final rowPosts = posts.sublist(start, end);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: rowIndex < rowCount - 1 ? gap : 0,
                    ),
                    child: columns == 1
                        ? SelectablePostCard(
                            post: rowPosts.first,
                            metrics: cardMetrics,
                            isSelected: state.selectedPostIds
                                .contains(rowPosts.first.id),
                            onSelectionChanged: (selected) =>
                                togglePostSelection(
                              context,
                              rowPosts.first.id,
                              selected ?? false,
                            ),
                            onTap: () => onPostTap(rowPosts.first),
                          )
                        : Row(
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
                                            isSelected: state.selectedPostIds
                                                .contains(rowPosts[i].id),
                                            onSelectionChanged: (selected) =>
                                                togglePostSelection(
                                              context,
                                              rowPosts[i].id,
                                              selected ?? false,
                                            ),
                                            onTap: () =>
                                                onPostTap(rowPosts[i]),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                  );
                },
                childCount: rowCount,
              ),
            ),
            if (useInfiniteScroll && state.isLoadingMore)
              const SliverToBoxAdapter(child: PostsLoadMoreIndicator()),
            if (useInfiniteScroll &&
                state.hasReachedMax &&
                posts.isNotEmpty)
              SliverToBoxAdapter(child: PostsEndOfListLabel()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}
