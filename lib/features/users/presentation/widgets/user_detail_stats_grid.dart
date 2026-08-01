import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';import '../../../../core/utils/coin_format.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_wallet_entity.dart';
import '../utils/user_detail_layout_metrics.dart';
import 'user_follow_connections_sheet.dart';

class UserDetailStatCard extends StatelessWidget {
  const UserDetailStatCard(
    this.label,
    this.value,
    this.icon,
    this.accentColor, {
    super.key,
    this.onTap,
    this.compact = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final metrics = userDetailLayoutMetrics(width);
    final iconSize = metrics.statsIconSize;
    final iconPad = metrics.statsIconPadding;
    final padding = metrics.statsCardPadding;
    final radius = 12.0;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Intrinsic width: hug content so cards cluster tightly in a Wrap/Row.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: iconSize),
          ),
          SizedBox(width: compact ? 6 : 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class UserDetailStatsGrid extends StatelessWidget {
  const UserDetailStatsGrid({
    super.key,
    required this.user,
    this.wallet,
  });

  final UserEntity user;
  final UserWalletEntity? wallet;

  static double _balanceCoins(UserWalletEntity? wallet, UserEntity user) {
    final w = wallet ?? user.wallet;
    return w?.balanceCoins ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final followListsEnabled =
        !user.isProfileLocked || PermissionManager.canReadUsers(context);

    void openFollowConnections(int initialTab) {
      showUserFollowConnectionsSheet(
        context,
        user,
        initialTab: initialTab,
      );
    }

    final balance = _balanceCoins(wallet, user);

    final stats = [
      (
        l10n.t('followers'),
        user.followerCount.toString(),
        Icons.people_alt_rounded,
        scheme.primary,
        followListsEnabled ? () => openFollowConnections(0) : null,
      ),
      (
        l10n.t('following'),
        user.followingCount.toString(),
        Icons.person_add_alt_1_rounded,
        scheme.tertiary,
        followListsEnabled ? () => openFollowConnections(1) : null,
      ),
      (
        l10n.t('posts'),
        user.postCount.toString(),
        Icons.video_collection_rounded,
        scheme.secondary,
        null,
      ),
      (
        l10n.tOr('userBalance', 'Balance'),
        CoinFormat.coins(balance),
        Icons.account_balance_wallet_rounded,
        const Color(0xFFCA8A04),
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = userDetailLayoutMetrics(constraints.maxWidth);
        final gap = metrics.statsGap;

        final cards = [
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
        ];

        // Cluster cards tightly; wrap only when the row can't fit.
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: cards,
          ),
        );
      },
    );
  }
}
