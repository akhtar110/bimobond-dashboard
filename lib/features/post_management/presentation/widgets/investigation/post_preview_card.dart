import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../posts/presentation/utils/post_date_format.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

/// Social-style post preview for moderator context.
class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({super.key, required this.post, this.dense = false});

  final ManagedPostEntity post;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final createdLabel = formatPostCreatedDateTime(
      post.createdAt,
      locale: Localizations.localeOf(context).languageCode,
      compact: dense,
    );
    final displayName = post.userFullName?.isNotEmpty == true
        ? post.userFullName!
        : (post.userName ?? post.userId);
    final statusColor = postStatusColorFromScheme(scheme, post.status);
    final avatarRadius = dense ? 14.0 : 18.0;

    return PostSurfaceCard(
      dense: dense,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!dense)
            Row(
              children: [
                Text(
                  l10n.tOr('postPreview', 'Post Preview'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    postStatusLabel(l10n, post.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          if (!dense) const SizedBox(height: InvestigationTheme.s12),
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: post.userProfileImage != null &&
                        post.userProfileImage!.isNotEmpty
                    ? CachedNetworkImageProvider(post.userProfileImage!)
                    : null,
                child: post.userProfileImage == null ||
                        post.userProfileImage!.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (post.userIsVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (post.userName != null)
                      Text(
                        '@${post.userName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                createdLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (post.category != null && post.category!.isNotEmpty) ...[
            const SizedBox(height: InvestigationTheme.s8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('#${post.category}'),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
