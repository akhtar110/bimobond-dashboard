import 'package:flutter/material.dart';

import '../utils/wallets_responsive.dart';

abstract final class WalletsSpace {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class WalletsDashboardShell extends StatelessWidget {
  const WalletsDashboardShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.scrollController,
  });

  final Widget child;
  final bool scrollable;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final metrics = walletsMetricsOf(context);
    final edgeInsets = EdgeInsets.fromLTRB(
      metrics.pageHorizontalPadding,
      metrics.pageTopPadding,
      metrics.pageHorizontalPadding,
      metrics.pageBottomPadding,
    );

    if (!scrollable) {
      return Padding(padding: edgeInsets, child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SingleChildScrollView(
          controller: scrollController,
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: viewportWidth,
              maxWidth: viewportWidth,
            ),
            child: Padding(padding: edgeInsets, child: child),
          ),
        );
      },
    );
  }
}

class WalletsDashboardCard extends StatelessWidget {
  const WalletsDashboardCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);
    return Material(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.dashboardCardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(metrics.cardPadding),
        child: child,
      ),
    );
  }
}

class WalletsMetricTile extends StatelessWidget {
  const WalletsMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WalletsDashboardCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: WalletsSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletsStatusChip extends StatelessWidget {
  const WalletsStatusChip({
    super.key,
    required this.label,
    this.tone = WalletsChipTone.neutral,
  });

  final String label;
  final WalletsChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      WalletsChipTone.success => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      WalletsChipTone.warning => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      WalletsChipTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      WalletsChipTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

enum WalletsChipTone { success, warning, error, neutral }

WalletsChipTone statusChipTone(String status) {
  return switch (status.toUpperCase()) {
    'COMPLETED' || 'APPROVED' => WalletsChipTone.success,
    'PENDING' => WalletsChipTone.warning,
    'FAILED' || 'REJECTED' || 'REFUNDED' => WalletsChipTone.error,
    _ => WalletsChipTone.neutral,
  };
}
