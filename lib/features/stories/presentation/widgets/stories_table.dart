import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../posts/presentation/widgets/posts_table_view.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/story_entity.dart';
import '../utils/stories_admin_l10n.dart';
import 'story_card.dart';

class StoriesTable extends StatelessWidget {
  const StoriesTable({
    super.key,
    required this.stories,
    required this.onStoryTap,
    required this.onStoryAction,
  });

  final List<StoryEntity> stories;
  final ValueChanged<StoryEntity> onStoryTap;
  final void Function(StoryEntity story, StoryCardActionType action) onStoryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canUpdate = PermissionManager.canUpdateStories(context);
    final canDelete = PermissionManager.canDeleteStories(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = postsTableDensityForWidth(constraints.maxWidth);

        return Column(
          children: [
            Container(
              height: kPostsTableHeaderHeight,
              color: scheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(width: 52, child: Text('Media', style: _headerStyle(context))),
                  Expanded(flex: 3, child: Text('Story', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('Author', style: _headerStyle(context))),
                  if (density != PostsTableDensity.compact)
                    Expanded(child: Text('Status', style: _headerStyle(context))),
                  Expanded(child: Text('Views', style: _headerStyle(context))),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            for (final story in stories)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onStoryTap(story),
                  child: Container(
                    height: kPostsTableRowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: story.validImageThumbnailUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: story.validImageThumbnailUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : (story.isVideo
                                    ? Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              scheme.primary.withValues(alpha: 0.25),
                                              scheme.surfaceContainerHighest,
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: scheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: scheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.auto_stories_outlined,
                                          color: scheme.onSurfaceVariant,
                                          size: 18,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Text(
                            story.description.trim().isEmpty
                                ? story.id
                                : story.description.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            StoriesAdminL10n.authorName(context, story),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (density != PostsTableDensity.compact)
                          Expanded(
                            child: Text(
                              StoriesAdminL10n.statusLabel(context, story.status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Expanded(
                          child: Text('${story.viewCount}'),
                        ),
                        PopupMenuButton<StoryCardActionType>(
                          onSelected: (action) => onStoryAction(story, action),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: StoryCardActionType.viewDetails,
                              child: Text(StoriesAdminL10n.viewDetails(context)),
                            ),
                            if (canUpdate)
                              PopupMenuItem(
                                value: StoryCardActionType.edit,
                                child: Text(StoriesAdminL10n.editStory(context)),
                              ),
                            if (canDelete)
                              PopupMenuItem(
                                value: StoryCardActionType.delete,
                                child: Text(StoriesAdminL10n.deleteStory(context)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  TextStyle? _headerStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
}
