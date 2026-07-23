import 'package:flutter/material.dart';

import '../../../posts/presentation/utils/posts_responsive.dart';
import '../../domain/entities/story_entity.dart';
import '../bloc/stories_state.dart';
import 'stories_grid.dart';
import 'stories_pagination_bar.dart';
import 'stories_table.dart';
import 'story_card.dart';

class StoriesContent extends StatelessWidget {
  const StoriesContent({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onStoryTap,
    required this.onStoryAction,
  });

  final StoriesLoaded state;
  final ScrollController scrollController;
  final ValueChanged<StoryEntity> onStoryTap;
  final void Function(StoryEntity story, StoryCardActionType action)
      onStoryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = PostsLayoutMetrics(
      getPostsDeviceType(MediaQuery.sizeOf(context).width),
    );

    final feed = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: state.useGridView
          ? StoriesGrid(
              key: const ValueKey('stories_grid'),
              stories: state.stories,
              onStoryTap: onStoryTap,
              onStoryAction: onStoryAction,
            )
          : StoriesTable(
              key: const ValueKey('stories_table'),
              stories: state.stories,
              onStoryTap: onStoryTap,
              onStoryAction: onStoryAction,
            ),
    );

    final scrollableFeed = SingleChildScrollView(
      controller: scrollController,
      physics: metrics.useInfiniteScroll
          ? AlwaysScrollableScrollPhysics(parent: metrics.listScrollPhysics)
          : metrics.listScrollPhysics,
      child: feed,
    );

    final applyingOverlay = state.isApplyingFilters || state.isRefreshing
        ? Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.08),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;

    if (!metrics.useDesktopPagination) {
      return Stack(
        children: [
          scrollableFeed,
          ?applyingOverlay,
          if (state.isLoadingMore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
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
              scrollableFeed,
              ?applyingOverlay,
            ],
          ),
        ),
        const SizedBox(height: 10),
        StoriesPaginationBar(
          currentPage: state.currentPage,
          lastPage: state.totalPages,
          total: state.total,
          itemCount: state.stories.length,
        ),
      ],
    );
  }
}
