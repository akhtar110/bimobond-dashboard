import 'package:flutter/material.dart';

import '../utils/promotions_responsive.dart';

abstract final class PromotionsBreakpoints {
  static const double smallDesktop = 1280;
  static const double desktop = 1440;
  static const double largeDesktop = 1600;
  static const double ultraWide = 1920;
  static const double maxContentWidth = 1800;
}

abstract final class PromotionsSpace {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class PromotionsDashboardShell extends StatelessWidget {
  const PromotionsDashboardShell({
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
    final width = MediaQuery.sizeOf(context).width;
    final metrics = PromotionsLayoutMetrics(getPromotionsDeviceType(width));

    final edgeInsets = EdgeInsets.fromLTRB(
      metrics.pageHorizontalPadding,
      metrics.pageTopPadding,
      metrics.pageHorizontalPadding,
      metrics.pageBottomPadding,
    );

    // Non-scrollable: preserve tight height constraints so Expanded children work.
    // We skip Align so the Column gets the exact bounded height from its parent.
    if (!scrollable) {
      return Padding(
        padding: edgeInsets,
        child: child,
      );
    }

    // Scrollable: bind content width to viewport so filters/tables layout correctly.
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.sizeOf(context).width;
        final viewportWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : mediaWidth;

        return SingleChildScrollView(
          controller: scrollController,
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: viewportWidth,
              maxWidth: viewportWidth,
            ),
            child: Padding(
              padding: edgeInsets,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class DashboardCard extends StatefulWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PromotionsSpace.xl),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _hovered = false;

  void _setHovered(bool hovered) {
    if (_hovered == hovered || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == hovered) return;
      setState(() => _hovered = hovered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = promotionsMetricsOf(context);
    final radius = metrics.cardRadius;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: widget.padding == const EdgeInsets.all(PromotionsSpace.xl)
          ? EdgeInsets.all(metrics.cardPadding)
          : widget.padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: _hovered ? 0.1 : 0.05),
            blurRadius: _hovered ? (metrics.isMobile ? 16 : 24) : (metrics.isMobile ? 10 : 16),
            offset: Offset(0, _hovered ? (metrics.isMobile ? 4 : 8) : (metrics.isMobile ? 2 : 4)),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class MetricCard extends StatefulWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? accent;

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _hovered = false;

  void _setHovered(bool hovered) {
    if (_hovered == hovered || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == hovered) return;
      setState(() => _hovered = hovered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final metrics = promotionsMetricsOf(context);
    final iconBox = metrics.metricIconSize;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(metrics.metricCardPadding),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(metrics.isMobile ? 14 : 20),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: _hovered ? 0.1 : 0.05),
              blurRadius: _hovered ? (metrics.isMobile ? 14 : 22) : (metrics.isMobile ? 8 : 14),
              offset: Offset(0, _hovered ? (metrics.isMobile ? 4 : 7) : (metrics.isMobile ? 2 : 4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _hovered ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(metrics.isMobile ? 10 : 13),
                  ),
                  child: Icon(
                    widget.icon,
                    color: accent,
                    size: metrics.isMobile ? 17 : 21,
                  ),
                ),
                const Spacer(),
                if (_hovered)
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
              ],
            ),
            const SizedBox(height: PromotionsSpace.md),
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    fontSize: metrics.isMobile ? 11 : null,
                  ),
            ),
            SizedBox(height: metrics.isMobile ? 4 : PromotionsSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.6,
                      height: 1.1,
                      fontSize: metrics.isMobile ? 20 : null,
                    ),
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: PromotionsSpace.sm),
              Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int promotionsMetricColumns(double width) {
  final device = getPromotionsDeviceType(width);
  if (device == PromotionsDeviceType.mobileSmall) return 1;
  if (device == PromotionsDeviceType.mobileLarge) return 2;
  if (width >= 1280) return 4;
  if (width >= 920) return 3;
  return 2;
}

double promotionsMetricAspectRatio(int columns) {
  return switch (columns) {
    1 => 2.4,
    2 => 1.55,
    3 => 1.5,
    _ => 1.45,
  };
}
