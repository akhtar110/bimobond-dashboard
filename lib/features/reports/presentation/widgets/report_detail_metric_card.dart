import 'package:flutter/material.dart';

import '../utils/reports_center_theme.dart';

/// Responsive KPI grid for report detail pages.
/// Default: **2 cards per row** on phones/tablets; 4 on very wide; 1 on narrow.
class ReportDetailMetricsGrid extends StatelessWidget {
  const ReportDetailMetricsGrid({
    super.key,
    required this.children,
    this.compact = false,
    this.hasSubtitle = false,
  });

  final List<Widget> children;
  final bool compact;
  final bool hasSubtitle;

  static int columnsForWidth(double width) {
    if (width >= 1000) return 4;
    if (width >= 420) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = columnsForWidth(width);
        final spacing = compact ? 8.0 : 12.0;
        final tileHeight = (hasSubtitle ? 92.0 : 78.0) - (compact ? 6.0 : 0.0);

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: tileHeight,
          ),
          children: children,
        );
      },
    );
  }
}

/// KPI tile used across report detail screens.
class ReportDetailMetricCard extends StatelessWidget {
  const ReportDetailMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = accent ?? scheme.primary;

    return DecoratedBox(
      decoration: ReportsCenterTheme.kpiCard(scheme, accent: tone),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: ReportsCenterTheme.accentWash(scheme, tone),
                borderRadius:
                    BorderRadius.circular(ReportsCenterTheme.radiusSm),
                border: Border.all(color: tone.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.35,
                      height: 1.05,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Count-only metric card for period-activity sections.
class ReportDetailCountMetricCard extends StatelessWidget {
  const ReportDetailCountMetricCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.accent,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ReportDetailMetricCard(
      title: title,
      value: '$count',
      icon: icon,
      accent: accent,
    );
  }
}
