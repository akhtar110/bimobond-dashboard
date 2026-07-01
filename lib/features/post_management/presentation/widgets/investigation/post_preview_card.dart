import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

/// Social-style post preview for moderator context.
class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({super.key, required this.post});

  final ManagedPostEntity post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final displayName = post.userFullName?.isNotEmpty == true
        ? post.userFullName!
        : (post.userName ?? post.userId);
    final statusColor = postStatusColorFromScheme(scheme, post.status);

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
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
          const SizedBox(height: InvestigationTheme.s12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
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
              const SizedBox(width: 10),
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
                dateFormat.format(post.createdAt),
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
