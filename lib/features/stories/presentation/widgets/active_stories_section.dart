import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../post_management/domain/entities/post_management_nav_result.dart';
import '../../../post_management/presentation/utils/post_management_navigation.dart';
import '../../../posts/presentation/utils/posts_page_refresh.dart';
import '../../../posts/presentation/utils/posts_responsive.dart';
import '../../domain/entities/active_story_entity.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_grouping.dart';
import '../utils/stories_l10n.dart';
import 'story_viewer_dialog.dart';

class ActiveStoriesSection extends StatelessWidget {
  const ActiveStoriesSection({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoriesBloc, StoriesState, List<ActiveStoryUserGroup>?>(
      selector: (state) {
        if (state is StoriesLoaded && state.stories.isNotEmpty) {
          return groupActiveStoriesByUser(state.stories);
        }
        return null;
      },
      builder: (context, groups) {
        if (groups == null || groups.isEmpty) {
          return const SizedBox.shrink();
        }

        final m = metrics ??
            PostsLayoutMetrics(
              getPostsDeviceType(MediaQuery.sizeOf(context).width),
            );

        return Padding(
          padding: EdgeInsets.only(
            top: m.storyStripVerticalPadding,
            bottom: m.storyStripVerticalPadding + 2,
          ),
          child: _ActiveStoriesStrip(
            groups: groups,
            metrics: m,
            onStoryTap: (index) => _openStory(context, groups[index]),
          ),
        );
      },
    );
  }

  Future<void> _openStory(
    BuildContext context,
    ActiveStoryUserGroup group,
  ) async {
    final bloc = context.read<StoriesBloc>();
    final state = bloc.state;
    if (state is! StoriesLoaded || state.stories.isEmpty) return;

    final userStories = group.stories;
    if (userStories.isEmpty) return;

    final initialIndex = 0;
    final globalIndex = globalStoryIndex(state.stories, userStories[initialIndex]);
    if (globalIndex >= 0) {
      bloc.add(OpenStoryEvent(globalIndex));
    }

    final result = await showStoryViewerDialog(
      context,
      stories: userStories,
      initialIndex: initialIndex,
      onIndexChanged: (nextIndex) {
        if (nextIndex < 0 || nextIndex >= userStories.length) return;
        final nextGlobalIndex =
            globalStoryIndex(state.stories, userStories[nextIndex]);
        if (nextGlobalIndex >= 0) {
          bloc.add(OpenStoryEvent(nextGlobalIndex));
        }
      },
      onViewDetails: (story) => _openPostDetails(context, story),
    );

    if (result == true && context.mounted) {
      refreshPostsPageFeed(context);
    }
  }

  Future<void> _openPostDetails(
    BuildContext context,
    ActiveStoryEntity story,
  ) {
    return navigateToPostManagementFromFeed(
      context,
      post: story.postData,
      onResult: (PostManagementNavResult result, _) {
        if (!context.mounted) return;
        if (result.deleted || result.post != null) {
          refreshPostsPageFeed(context);
        }
      },
    );
  }
}

class _ActiveStoriesStrip extends StatelessWidget {
  const _ActiveStoriesStrip({
    required this.groups,
    required this.metrics,
    required this.onStoryTap,
  });

  final List<ActiveStoryUserGroup> groups;
  final PostsLayoutMetrics metrics;
  final ValueChanged<int> onStoryTap;

  @override
  Widget build(BuildContext context) {
    final bubbleSize = metrics.storyBubbleSize;
    final labelSpace = metrics.isMobile ? 26.0 : 32.0;

    return SizedBox(
      height: bubbleSize + labelSpace,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: groups.length,
        separatorBuilder: (_, _) => SizedBox(width: metrics.filterGap + 2),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _StoryBubbleCard(
            story: group.previewStory,
            storyCount: group.stories.length,
            size: bubbleSize,
            compact: metrics.isMobile,
            onTap: () => onStoryTap(index),
          );
        },
      ),
    );
  }
}

class _StoryBubbleCard extends StatefulWidget {
  const _StoryBubbleCard({
    required this.story,
    required this.storyCount,
    required this.size,
    required this.onTap,
    this.compact = false,
  });

  final ActiveStoryEntity story;
  final int storyCount;
  final double size;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_StoryBubbleCard> createState() => _StoryBubbleCardState();
}

class _StoryBubbleCardState extends State<_StoryBubbleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final story = widget.story;
    final label = StoriesL10n.bubbleLabel(context, story);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.size,
            child: Column(
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  padding: EdgeInsets.all(widget.compact ? 2 : 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: story.thumbnailUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              placeholder: (_, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                              ),
                              errorWidget: (_, _, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: scheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (widget.storyCount > 1)
                              Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        '${widget.storyCount}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: scheme.onPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (story.isVideo)
                              Align(
                                alignment: AlignmentDirectional.bottomEnd,
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.scrim.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        size: 12,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.compact ? 3 : 5),
                SizedBox(
                  width: widget.size,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: widget.compact ? 8 : 9.5,
                          height: 1.1,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
