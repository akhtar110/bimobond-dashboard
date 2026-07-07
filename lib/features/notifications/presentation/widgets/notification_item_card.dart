import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/notification_entity.dart';
import '../utils/notification_labels.dart';

/// Reusable card for displaying a single admin notification entry.
/// Used in both [UserActivityNotificationsTab] and [NotificationFeedPanel].
class NotificationItemCard extends StatelessWidget {
  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.isDark,
    this.onTap,
  });

  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = notification;

    final actor = n.actor;
    final typeColor = _typeColor(n.type, scheme);
    final typeIcon = _typeIcon(n.type);
    final description = notificationActionText(l10n, n.type, message: n.message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: n.isRead
                ? scheme.surface
                : scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.isRead
                  ? scheme.outlineVariant
                  : scheme.primary.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actor avatar + type badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _Avatar(
                    url: actor?.avatarUrl,
                    fallback: actor?.username ?? '?',
                    size: 20,
                    scheme: scheme,
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(typeIcon, size: 10, color: typeColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + timestamp row
                    Row(
                      children: [
                        _TypeBadge(
                          label: notificationFeedTypeLabel(l10n, n.type),
                          color: typeColor,
                        ),
                        const Spacer(),
                        if (!n.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                            ),
                          ),
                        Text(
                          notificationRelativeTime(l10n, n.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Actor name + description
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                        ),
                        children: [
                          if (actor != null)
                            TextSpan(
                              text: actor.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (actor != null) const TextSpan(text: ' '),
                          TextSpan(text: description),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Optional post thumbnail
                    if (_postThumbnail(n) != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _postThumbnail(n)!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, err) => Container(
                            width: 56,
                            height: 56,
                            color: scheme.surfaceContainerHighest,
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 20,
                                color: scheme.onSurfaceVariant),
                          ),
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
    );
  }

  String? _postThumbnail(NotificationEntity n) {
    final thumb = n.post?['thumbnailUrl']?.toString();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    return n.post?['videoUrl']?.toString();
  }

  Color _typeColor(String type, ColorScheme scheme) {
    switch (type.toUpperCase()) {
      case 'POST_LIKE':
        return scheme.error;
      case 'COMMENT':
      case 'COMMENT_LIKE':
        return scheme.primary;
      case 'FOLLOW':
        return scheme.tertiary;
      case 'MENTION':
        return scheme.secondary;
      case 'REPOST':
        return scheme.tertiary;
      case 'ADMIN_MESSAGE':
        return scheme.primary;
      case 'BROADCAST':
        return scheme.error;
      default:
        return scheme.secondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'POST_LIKE':
        return Icons.favorite_rounded;
      case 'COMMENT':
        return Icons.comment_rounded;
      case 'COMMENT_LIKE':
        return Icons.thumb_up_rounded;
      case 'FOLLOW':
        return Icons.person_add_rounded;
      case 'MENTION':
        return Icons.alternate_email_rounded;
      case 'REPOST':
        return Icons.repeat_rounded;
      case 'ADMIN_MESSAGE':
        return Icons.admin_panel_settings_rounded;
      case 'BROADCAST':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.fallback,
    required this.size,
    required this.scheme,
  });

  final String? url;
  final String fallback;
  final double size;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: url != null && url!.isNotEmpty
          ? CachedNetworkImageProvider(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Text(
              fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: size * 0.75,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
