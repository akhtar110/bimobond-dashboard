import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../posts/presentation/widgets/post_card.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/story_entity.dart';
import '../utils/stories_admin_l10n.dart';

typedef StoryCardAction = void Function(StoryCardActionType type);

enum StoryCardActionType { viewDetails, edit, delete }

/// Compact story grid card — sized like [PostCard]; full details live in the
/// details popup.
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

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == value) return;
      setState(() => _hovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final story = widget.story;
    final canUpdate = PermissionManager.canUpdateStories(context);
    final canDelete = PermissionManager.canDeleteStories(context);
    final description = story.description.trim();
    final dateLabel = story.createdAt != null
        ? DateFormat('MMM d, yyyy').format(story.createdAt!.toLocal())
        : '—';
    final viewsLabel = StoriesAdminL10n.viewsLabel(context, story.viewCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final bodyPadding = compact ? 6.0 : 8.0;
        final radius = compact ? 10.0 : 12.0;
        final nameSize = compact ? 10.5 : 11.5;
        final metaSize = compact ? 9.0 : 10.0;

        return MouseRegion(
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
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
                      if (_hovered)
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
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
                              if (story.validImageThumbnailUrl != null)
                                CachedNetworkImage(
                                  imageUrl: story.validImageThumbnailUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 480,
                                  placeholder: (_, _) => ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: (_, _, _) =>
                                      _buildVideoOrFallback(
                                    context,
                                    scheme,
                                    story,
                                  ),
                                )
                              else
                                _buildVideoOrFallback(context, scheme, story),
                              if (story.isVideo &&
                                  story.validImageThumbnailUrl != null)
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
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.62),
                                    shape: const CircleBorder(),
                                    elevation: 1,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.35,
                                    ),
                                    child: PopupMenuButton<StoryCardActionType>(
                                      padding: EdgeInsets.zero,
                                      tooltip: MaterialLocalizations.of(
                                        context,
                                      ).moreButtonTooltip,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onSelected: (action) =>
                                          widget.onAction?.call(action),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value:
                                              StoryCardActionType.viewDetails,
                                          child: Text(
                                            StoriesAdminL10n.viewDetails(
                                              context,
                                            ),
                                          ),
                                        ),
                                        if (canUpdate)
                                          PopupMenuItem(
                                            value: StoryCardActionType.edit,
                                            child: Text(
                                              StoriesAdminL10n.editStory(
                                                context,
                                              ),
                                            ),
                                          ),
                                        if (canDelete)
                                          PopupMenuItem(
                                            value: StoryCardActionType.delete,
                                            child: Text(
                                              StoriesAdminL10n.deleteStory(
                                                context,
                                              ),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                            StoriesAdminL10n.authorName(
                                              context,
                                              story,
                                            )[0]
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
                                      mainAxisSize: MainAxisSize.min,
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
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: nameSize,
                                                height: 1.2,
                                                letterSpacing: -0.1,
                                                color: scheme.onSurface,
                                              ),
                                        ),
                                        SizedBox(height: compact ? 2 : 3),
                                        Text(
                                          '$dateLabel · $viewsLabel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: metaSize,
                                            color: scheme.onSurfaceVariant,
                                            height: 1.1,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              Text(
                                description.isEmpty ? '—' : description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: metaSize + 0.5,
                                      height: 1.2,
                                      color: scheme.onSurface,
                                    ),
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
                                ],
                              ),
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

  Widget _buildVideoOrFallback(
    BuildContext context,
    ColorScheme scheme,
    StoryEntity story,
  ) {
    if (story.isVideo) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.25),
              scheme.surfaceContainerHighest,
              scheme.surfaceContainerLow,
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.scrim.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.auto_stories_outlined,
        color: scheme.onSurfaceVariant,
        size: 32,
      ),
    );
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
