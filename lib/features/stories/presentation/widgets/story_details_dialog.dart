import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/post_media_preview.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/story_entity.dart';
import '../utils/stories_admin_l10n.dart';

Future<void> showStoryDetailsDialog(
  BuildContext context, {
  required StoryEntity story,
  VoidCallback? onEdit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StoryDetailsDialog(
      story: story,
      onEdit: PermissionManager.canUpdateStories(context) ? onEdit : null,
    ),
  );
}

class StoryDetailsDialog extends StatelessWidget {
  const StoryDetailsDialog({
    super.key,
    required this.story,
    this.onEdit,
  });

  final StoryEntity story;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = story.user;
    final media = story.primaryMedia;

    return AlertDialog(
      title: Text(StoriesAdminL10n.viewDetails(context)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (media != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PostMediaPreview(
                    thumbnailUrl: story.validImageThumbnailUrl,
                    videoUrl: media.isVideo ? media.url : null,
                    type: media.isVideo ? 'VIDEO' : 'IMAGE',
                    height: 380,
                    autoplay: true,
                    showSeekBar: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _InfoSection(
                title: 'Story',
                rows: [
                  _InfoRow('ID', story.id),
                  _InfoRow('Description', story.description),
                  _InfoRow(
                    'Status',
                    StoriesAdminL10n.statusLabel(context, story.status),
                  ),
                  _InfoRow(
                    'Privacy',
                    StoriesAdminL10n.privacyLabel(context, story.privacyStatus),
                  ),
                  _InfoRow('Views', '${story.viewCount}'),
                  _InfoRow('TTL', '${story.ttlHours}h'),
                  _InfoRow(
                    'Expires',
                    StoriesAdminL10n.formatDate(context, story.expiresAt),
                  ),
                  _InfoRow(
                    'Created',
                    StoriesAdminL10n.formatDate(context, story.createdAt),
                  ),
                  _InfoRow(
                    'Updated',
                    StoriesAdminL10n.formatDate(context, story.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'User',
                rows: [
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(user.displayName[0].toUpperCase())
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    if (user.isVerified) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                    ],
                                    if (user.isPrivate) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 14,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ],
                                ),
                                Text('@${user.username}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  _InfoRow('User ID', story.userId),
                ],
              ),
              if (story.soundSegment != null) ...[
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Sound',
                  rows: [
                    _InfoRow('Title', story.soundSegment!.title ?? '—'),
                    _InfoRow('Audio', story.soundSegment!.audioUrl ?? '—'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (onEdit != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit!();
            },
            child: Text(StoriesAdminL10n.editStory(context)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
