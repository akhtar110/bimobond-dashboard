import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/activity_context.dart';
import 'post_surface_card.dart';

class ActivityContextCard extends StatelessWidget {
  const ActivityContextCard({
    super.key,
    required this.activityContext,
    required this.isDark,
  });

  final ActivityContext activityContext;
  final bool isDark;

  Color get _accent {
    switch (activityContext.type) {
      case ActivityType.comment:
        return const Color(0xFF3B82F6);
      case ActivityType.like:
        return const Color(0xFFEC4899);
      case ActivityType.mention:
        return const Color(0xFF8B5CF6);
      case ActivityType.post:
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _title(AppLocalizations l10n) {
    switch (activityContext.type) {
      case ActivityType.comment:
        return l10n.t('activityCommentTitle');
      case ActivityType.like:
        return l10n.t('activityLikeTitle');
      case ActivityType.mention:
        return l10n.t('activityMentionTitle');
      case ActivityType.post:
        return l10n.t('activityPostTitle');
      case ActivityType.activityFeed:
        return l10n.t('activityFeedTitle');
      default:
        return l10n.t('activityContextTitle');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = _accent;
    final date = activityContext.activityDate;
    final dateStr = date != null
        ? DateFormat('MMM d, yyyy · HH:mm').format(date)
        : null;

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _title(l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          if (dateStr != null) ...[
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (activityContext.type == ActivityType.comment &&
              activityContext.commentText != null) ...[
            const SizedBox(height: 10),
            Text(
              '"${activityContext.commentText!}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
          if (activityContext.type == ActivityType.like &&
              activityContext.likeId != null &&
              activityContext.likeId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.t('likeId')}: ${activityContext.likeId}',
              style: theme.textTheme.labelSmall,
            ),
          ],
          if (activityContext.type == ActivityType.mention) ...[
            if (activityContext.mentionText != null) ...[
              const SizedBox(height: 8),
              Text(activityContext.mentionText!, style: theme.textTheme.bodyMedium),
            ],
            if (activityContext.mentionSource != null) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.t('mentionSource')}: ${activityContext.mentionSource}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (activityContext.mentionedUserNames.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.t('mentionedUsers')}: ${activityContext.mentionedUserNames.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
          if (activityContext.postOwnerName != null &&
              activityContext.postOwnerName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${l10n.t('postOwner')}: ${activityContext.postOwnerName}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
