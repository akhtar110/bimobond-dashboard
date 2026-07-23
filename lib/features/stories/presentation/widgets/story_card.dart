import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../posts/presentation/widgets/post_card.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/story_entity.dart';
import '../utils/stories_admin_l10n.dart';

typedef StoryCardAction = void Function(StoryCardActionType type);

enum StoryCardActionType { viewDetails, edit, delete }

class StoryCard extends StatefulWidget {
  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.onAction,
  });

  final StoryEntity story;
  final VoidCallback? onTap;
  final StoryCardAction? onAction;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final story = widget.story;
    final canUpdate = PermissionManager.canUpdateStories(context);
    final canDelete = PermissionManager.canDeleteStories(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final bodyPadding = compact ? 6.0 : 8.0;
        final radius = compact ? 10.0 : 12.0;
        final thumbUrl = story.thumbnailUrl;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _hovered ? 1.01 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: _hovered
                          ? scheme.primary.withValues(alpha: 0.42)
                          : scheme.outlineVariant.withValues(alpha: 0.85),
                      width: _hovered ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(
                          alpha: _hovered
                              ? (isDark ? 0.45 : 0.12)
                              : (isDark ? 0.28 : 0.05),
                        ),
                        blurRadius: _hovered ? 18 : 10,
                        spreadRadius: _hovered ? 0.5 : 0,
                        offset: Offset(0, _hovered ? 8 : 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: compact
                              ? kPostCardThumbnailAspectCompact
                              : kPostCardThumbnailAspect,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (thumbUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: thumbUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 480,
                                  placeholder: (_, _) => ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: (_, _, _) => ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              else
                                ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.auto_stories_outlined,
                                    color: scheme.onSurfaceVariant,
                                    size: 32,
                                  ),
                                ),
                              if (story.isVideo)
                                Align(
                                  alignment: AlignmentDirectional.bottomEnd,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: scheme.scrim
                                            .withValues(alpha: 0.65),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.onAction != null)
                                PositionedDirectional(
                                  top: 6,
                                  end: 6,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: PopupMenuButton<StoryCardActionType>(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: scheme.onPrimary,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8,
                                            color: scheme.scrim
                                                .withValues(alpha: 0.65),
                                          ),
                                        ],
                                      ),
                                      onSelected: (action) =>
                                          widget.onAction?.call(action),
                                      itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: StoryCardActionType.viewDetails,
                                        child: Text(
                                          StoriesAdminL10n.viewDetails(context),
                                        ),
                                      ),
                                      if (canUpdate)
                                        PopupMenuItem(
                                          value: StoryCardActionType.edit,
                                          child: Text(
                                            StoriesAdminL10n.editStory(context),
                                          ),
                                        ),
                                      if (canDelete)
                                        PopupMenuItem(
                                          value: StoryCardActionType.delete,
                                          child: Text(
                                            StoriesAdminL10n.deleteStory(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            bodyPadding,
                            compact ? 5 : 6,
                            bodyPadding,
                            bodyPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: compact ? 10 : 11,
                                    backgroundColor: scheme.primaryContainer,
                                    backgroundImage:
                                        story.user?.avatarUrl != null
                                            ? CachedNetworkImageProvider(
                                                story.user!.avatarUrl!,
                                              )
                                            : null,
                                    child: story.user?.avatarUrl == null
                                        ? Text(
                                            StoriesAdminL10n
                                                .authorName(context, story)[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: compact ? 9 : 10,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onPrimaryContainer,
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: compact ? 5 : 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          StoriesAdminL10n.authorName(
                                            context,
                                            story,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (StoriesAdminL10n.authorUsername(story)
                                            .isNotEmpty)
                                          Text(
                                            StoriesAdminL10n.authorUsername(story),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              Text(
                                story.description.trim().isEmpty
                                    ? '—'
                                    : story.description.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  _BadgeChip(
                                    label: StoriesAdminL10n.statusLabel(
                                      context,
                                      story.status,
                                    ),
                                    color: _statusColor(scheme, story.status),
                                  ),
                                  _BadgeChip(
                                    label: StoriesAdminL10n.privacyLabel(
                                      context,
                                      story.privacyStatus,
                                    ),
                                    color: scheme.secondaryContainer,
                                  ),
                                  _BadgeChip(
                                    label: StoriesAdminL10n.activeIndicator(
                                      context,
                                      story,
                                    ),
                                    color: story.isActive
                                        ? scheme.primaryContainer
                                        : scheme.errorContainer,
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              Text(
                                [
                                  StoriesAdminL10n.viewsLabel(
                                    context,
                                    story.viewCount,
                                  ),
                                  StoriesAdminL10n.ttlHoursLabel(
                                    context,
                                    story.ttlHours,
                                  ),
                                  StoriesAdminL10n.formatDate(
                                    context,
                                    story.expiresAt,
                                  ),
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              if (story.createdAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMd(
                                    Localizations.localeOf(context).toString(),
                                  ).format(story.createdAt!.toLocal()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(ColorScheme scheme, String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return scheme.primaryContainer;
      case 'HIDDEN':
        return scheme.tertiaryContainer;
      case 'EXPIRED':
        return scheme.errorContainer;
      default:
        return scheme.surfaceContainerHighest;
    }
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
      ),
    );
  }
}
