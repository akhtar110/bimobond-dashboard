import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';

class UsersAnalyticsCards extends StatelessWidget {
  const UsersAnalyticsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocSelector<UsersBloc, UsersState, ({int total, int activeCount, int verifiedCount, int bannedCount})>(
      selector: (state) {
        if (state is UsersLoaded) {
          final total = state.total;
          final banned = state.users.where((u) => u.isBanned).length;
          final verified = state.users.where((u) => u.isVerified).length;
          final active = total - banned;
          return (
            total: total,
            activeCount: active,
            verifiedCount: verified,
            bannedCount: banned,
          );
        }
        return (total: 24593, activeCount: 18940, verifiedCount: 3120, bannedCount: 482);
      },
      builder: (context, stats) {
        final totalText = _formatNumber(stats.total);
        final activeText = _formatNumber(stats.activeCount);
        final verifiedText = _formatNumber(stats.verifiedCount);
        final bannedText = _formatNumber(stats.bannedCount);

        final totalTitle = l10n.tOr('totalUsers', 'Total Users');
        final activeTitle = l10n.tOr('activeUsers', 'Active Users');
        final verifiedTitle = l10n.tOr('verifiedUsers', 'Verified Users');
        final suspendedTitle = l10n.tOr('suspendedUsers', 'Suspended Users');

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 640;

            if (isCompact) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CompactStatCard(
                          title: totalTitle,
                          value: totalText,
                          change: '+12.4%',
                          isPositive: true,
                          icon: Icons.people_alt_rounded,
                          accentColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          title: activeTitle,
                          value: activeText,
                          change: '+8.1%',
                          isPositive: true,
                          icon: Icons.bolt_rounded,
                          accentColor: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactStatCard(
                          title: verifiedTitle,
                          value: verifiedText,
                          change: '+5.2%',
                          isPositive: true,
                          icon: Icons.verified_user_rounded,
                          accentColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          title: suspendedTitle,
                          value: bannedText,
                          change: '-2.1%',
                          isPositive: true,
                          icon: Icons.gavel_rounded,
                          accentColor: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _CompactStatCard(
                    title: totalTitle,
                    value: totalText,
                    change: '+12.4%',
                    isPositive: true,
                    icon: Icons.people_alt_rounded,
                    accentColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactStatCard(
                    title: activeTitle,
                    value: activeText,
                    change: '+8.1%',
                    isPositive: true,
                    icon: Icons.bolt_rounded,
                    accentColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactStatCard(
                    title: verifiedTitle,
                    value: verifiedText,
                    change: '+5.2%',
                    isPositive: true,
                    icon: Icons.verified_user_rounded,
                    accentColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactStatCard(
                    title: suspendedTitle,
                    value: bannedText,
                    change: '-2.1%',
                    isPositive: true,
                    icon: Icons.gavel_rounded,
                    accentColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatNumber(int val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    }
    if (val >= 1000) {
      final s = val.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return val.toString();
  }
}

class _CompactStatCard extends StatefulWidget {
  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color accentColor;

  @override
  State<_CompactStatCard> createState() => _CompactStatCardState();
}

class _CompactStatCardState extends State<_CompactStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.4)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: _isHovered ? 0.05 : 0.02),
              blurRadius: _isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        widget.value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (widget.isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.change,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.isPositive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
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
