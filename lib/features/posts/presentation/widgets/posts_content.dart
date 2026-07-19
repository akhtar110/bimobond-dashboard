import 'package:flutter/material.dart';

import '../../domain/enums/posts_view_type.dart';
import '../bloc/posts_bloc.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../utils/posts_responsive.dart';
import 'posts_grid_view.dart';
import 'posts_list_view.dart';
import 'posts_pagination_bar.dart';

class PostsContent extends StatelessWidget {
  const PostsContent({
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final metrics = PostsLayoutMetrics(
      getPostsDeviceType(MediaQuery.sizeOf(context).width),
    );

    final feed = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: state.viewType == PostsViewType.grid
          ? PostsGridView(
              key: const ValueKey('posts_grid'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
              useInfiniteScroll: metrics.useInfiniteScroll,
            )
          : PostsListView(
              key: const ValueKey('posts_list'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
              useInfiniteScroll: metrics.useInfiniteScroll,
            ),
    );

    if (!metrics.useDesktopPagination) {
      return Stack(
        children: [
          feed,
          if (state.isApplyingFilters)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x22000000),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              feed,
              if (state.isApplyingFilters)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x22000000),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PostsPaginationBar(
          currentPage: state.currentPage,
          lastPage: state.lastPage,
          total: state.total,
          itemCount: state.posts.length,
        ),
      ],
    );
  }
}
