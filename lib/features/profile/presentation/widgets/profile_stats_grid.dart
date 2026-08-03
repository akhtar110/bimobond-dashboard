import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final stats = [
      _StatItem(
        label: l10n.tOr('posts', 'Posts'),
        value: _formatNum(profile.postCount),
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF3B82F6), // Blue
      ),
      _StatItem(
        label: l10n.tOr('followers', 'Followers'),
        value: _formatNum(profile.followerCount),
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF10B981), // Emerald
      ),
      _StatItem(
        label: l10n.tOr('following', 'Following'),
        value: _formatNum(profile.followingCount),
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF8B5CF6), // Purple
      ),
      _StatItem(
        label: l10n.tOr('total_likes', 'Total Likes'),
        value: _formatNum(profile.totalLikes),
        icon: Icons.favorite_rounded,
        color: const Color(0xFFEC4899), // Pink
      ),
      _StatItem(
        label: l10n.tOr('coin_balance', 'Coin Balance'),
        value: profile.balanceCoins.toStringAsFixed(1),
        icon: Icons.monetization_on_rounded,
        color: const Color(0xFFF59E0B), // Amber/Gold
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 550
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 88,
          ),
          itemBuilder: (context, index) {
            final item = stats[index];
            return _StatCard(item: item);
          },
        );
      },
    );
  }

  static String _formatNum(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatefulWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? item.color.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: _hovered ? 0.08 : 0.02),
              blurRadius: _hovered ? 10 : 4,
              offset: Offset(0, _hovered ? 3 : 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: item.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
