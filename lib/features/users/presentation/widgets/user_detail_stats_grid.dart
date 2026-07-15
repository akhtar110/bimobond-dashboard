import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import 'user_follow_connections_sheet.dart';

class UserDetailStatCard extends StatelessWidget {
  const UserDetailStatCard(
    this.label,
    this.value,
    this.icon,
    this.accentColor, {
    super.key,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}

class UserDetailStatsGrid extends StatelessWidget {
  const UserDetailStatsGrid({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final followListsEnabled = !user.isProfileLocked;

    final stats = [
      (
        l10n.t('followers'),
        user.followerCount.toString(),
        Icons.people_alt_rounded,
        scheme.primary,
        followListsEnabled
            ? () => showUserFollowConnectionsSheet(
                  context,
                  user,
                  initialTab: 0,
                )
            : null,
      ),
      (
        l10n.t('following'),
        user.followingCount.toString(),
        Icons.person_add_alt_1_rounded,
        scheme.tertiary,
        followListsEnabled
            ? () => showUserFollowConnectionsSheet(
                  context,
                  user,
                  initialTab: 1,
                )
            : null,
      ),
      (
        l10n.t('posts'),
        user.postCount.toString(),
        Icons.video_collection_rounded,
        scheme.secondary,
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // On very narrow screens stack vertically, otherwise flow as a row.
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                UserDetailStatCard(
                  stats[i].$1,
                  stats[i].$2,
                  stats[i].$3,
                  stats[i].$4,
                  onTap: stats[i].$5,
                ),
              ],
            ],
          );
        }

        // Wrap so cards use their natural (intrinsic) width and stay clustered.
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in stats)
              IntrinsicWidth(
                child: UserDetailStatCard(
                  s.$1,
                  s.$2,
                  s.$3,
                  s.$4,
                  onTap: s.$5,
                ),
              ),
          ],
        );
      },
    );
  }
}
