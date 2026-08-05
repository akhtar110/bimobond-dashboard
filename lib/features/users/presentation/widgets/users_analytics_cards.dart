import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';

class UsersAnalyticsCards extends StatelessWidget {
  const UsersAnalyticsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocSelector<UsersBloc, UsersState, ({
      int total,
      int onlineCount,
      int verifiedCount,
      int bannedCount,
      bool isTotalSelected,
      bool isOnlineSelected,
      bool isVerifiedSelected,
      bool isBannedSelected,
      bool isLoading,
    })>(
      selector: (state) {
        if (state is UsersLoaded) {
          return (
            total: state.total,
            onlineCount: state.onlineCount,
            verifiedCount: state.verifiedCount,
            bannedCount: state.bannedCount,
            isTotalSelected: state.isCardTotalSelected,
            isOnlineSelected: state.isCardOnlineSelected,
            isVerifiedSelected: state.isCardVerifiedSelected,
            isBannedSelected: state.isCardBannedSelected,
            isLoading: false,
          );
        }
        if (state is UsersEmpty) {
          return (
            total: 0,
            onlineCount: 0,
            verifiedCount: 0,
            bannedCount: 0,
            isTotalSelected: true,
            isOnlineSelected: false,
            isVerifiedSelected: false,
            isBannedSelected: false,
            isLoading: false,
          );
        }
        return (
          total: 0,
          onlineCount: 0,
          verifiedCount: 0,
          bannedCount: 0,
          isTotalSelected: true,
          isOnlineSelected: false,
          isVerifiedSelected: false,
          isBannedSelected: false,
          isLoading: true,
        );
      },
      builder: (context, stats) {
        final locale = Localizations.localeOf(context).languageCode;
        final totalText =
            stats.isLoading ? '' : _formatNumber(stats.total, locale);
        final onlineText =
            stats.isLoading ? '' : _formatNumber(stats.onlineCount, locale);
        final verifiedText =
            stats.isLoading ? '' : _formatNumber(stats.verifiedCount, locale);
        final bannedText =
            stats.isLoading ? '' : _formatNumber(stats.bannedCount, locale);

        final totalTitle = l10n.tOr('totalUsers', 'Total Users');
        final onlineTitle = l10n.tOr('onlineNow', 'Online Now');
        final verifiedTitle = l10n.tOr('verifiedUsers', 'Verified Users');
        final suspendedTitle = l10n.tOr('suspendedUsers', 'Suspended Users');

        final bloc = context.read<UsersBloc>();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 960;

            final totalCard = _CompactStatCard(
              title: totalTitle,
              value: totalText,
              icon: Icons.people_alt_rounded,
              accentColor: Theme.of(context).colorScheme.primary,
              isLoading: stats.isLoading,
              isSelected: stats.isTotalSelected,
              onTap: () => bloc.add(ClearUsersListFiltersEvent()),
            );

            final onlineCard = _CompactStatCard(
              title: onlineTitle,
              value: onlineText,
              icon: Icons.wifi_rounded,
              accentColor: const Color(0xFF22C55E),
              isLoading: stats.isLoading,
              showPulse: !stats.isLoading && stats.onlineCount > 0,
              isSelected: stats.isOnlineSelected,
              onTap: () => bloc.add(ToggleOnlineCardFilterEvent()),
            );

            final verifiedCard = _CompactStatCard(
              title: verifiedTitle,
              value: verifiedText,
              icon: Icons.verified_user_rounded,
              accentColor: const Color(0xFF3B82F6),
              isLoading: stats.isLoading,
              isSelected: stats.isVerifiedSelected,
              onTap: () => bloc.add(ToggleVerifiedCardFilterEvent()),
            );

            final suspendedCard = _CompactStatCard(
              title: suspendedTitle,
              value: bannedText,
              icon: Icons.gavel_rounded,
              accentColor: const Color(0xFFEF4444),
              isLoading: stats.isLoading,
              isSelected: stats.isBannedSelected,
              onTap: () => bloc.add(ToggleBannedCardFilterEvent()),
            );

            if (!isWide) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: totalCard),
                      const SizedBox(width: 8),
                      Expanded(child: onlineCard),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: verifiedCard),
                      const SizedBox(width: 8),
                      Expanded(child: suspendedCard),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: totalCard),
                const SizedBox(width: 10),
                Expanded(child: onlineCard),
                const SizedBox(width: 10),
                Expanded(child: verifiedCard),
                const SizedBox(width: 10),
                Expanded(child: suspendedCard),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatNumber(int val, String locale) {
    if (val >= 1000000) {
      return NumberFormat.compact(locale: locale).format(val);
    }
    return NumberFormat.decimalPattern(locale).format(val);
  }
}

class _CompactStatCard extends StatefulWidget {
  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.isLoading = false,
    this.showPulse = false,
    this.isSelected = false,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final bool showPulse;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<_CompactStatCard> createState() => _CompactStatCardState();
}

class _CompactStatCardState extends State<_CompactStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.showPulse) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CompactStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final cardWidth = cardConstraints.maxWidth;
        final isUltraCompact = cardWidth < 140;

        final padding = isUltraCompact
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
        final iconPadding = isUltraCompact ? 3.0 : 4.0;
        final iconSize = isUltraCompact ? 12.0 : 14.0;
        final valueFontSize = isUltraCompact ? 13.0 : 14.0;
        final titleFontSize = isUltraCompact ? 9.5 : 10.5;
        final gap = isUltraCompact ? 5.0 : 7.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: padding,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.accentColor.withValues(alpha: 0.08)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.accentColor
                        : (_isHovered
                            ? widget.accentColor.withValues(alpha: 0.4)
                            : scheme.outlineVariant.withValues(alpha: 0.5)),
                    width: widget.isSelected ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(
                          alpha: widget.isSelected
                              ? 0.06
                              : (_isHovered ? 0.04 : 0.015)),
                      blurRadius: widget.isSelected ? 8 : (_isHovered ? 6 : 3),
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.icon,
                    size: iconSize,
                    color: widget.accentColor,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isSelected
                                    ? widget.accentColor
                                    : scheme.onSurfaceVariant,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: titleFontSize,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (widget.isSelected) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.check_circle_rounded,
                              size: titleFontSize + 2,
                              color: widget.accentColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      if (widget.isLoading)
                        Container(
                          width: 40,
                          height: 12,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.value,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: scheme.onSurface,
                                  fontSize: valueFontSize,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (widget.showPulse) ...[
                              const SizedBox(width: 4),
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (context, _) => Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.accentColor.withValues(alpha: _pulseAnim.value),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.accentColor.withValues(alpha: _pulseAnim.value * 0.5),
                                        blurRadius: 3,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
    );
      },
    );
  }
}
