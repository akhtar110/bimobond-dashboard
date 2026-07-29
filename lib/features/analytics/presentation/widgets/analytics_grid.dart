import 'package:flutter/material.dart';

/// Responsive column count for the 12-column analytics grid.
int analyticsGridColumns(double width) {
  if (width >= 1400) return 12;
  if (width >= 900) return 6;
  // Two columns on phones / small tablets so KPI cards stay compact.
  if (width >= 360) return 2;
  return 1;
}

class AnalyticsGrid extends StatelessWidget {
  const AnalyticsGrid({
    super.key,
    required this.width,
    required this.children,
    this.spacing = 12,
  });

  final double width;
  final List<AnalyticsGridItem> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = analyticsGridColumns(width);
    final gap = width < 720 ? (width < 480 ? 8.0 : 10.0) : spacing;

    if (columns == 1 || width <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i].child,
          ],
        ],
      );
    }

    final unitWidth = (width - gap * (columns - 1)) / columns;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final item in children)
          SizedBox(
            width: unitWidth * item.span(columns) +
                gap * (item.span(columns) - 1),
            child: item.child,
          ),
      ],
    );
  }
}

class AnalyticsGridItem {
  const AnalyticsGridItem({
    required this.child,
    required this.desktopSpan,
    this.tabletSpan,
  });

  final Widget child;
  final int desktopSpan;
  final int? tabletSpan;

  int span(int columns) {
    if (columns == 12) return desktopSpan;
    if (columns == 6) return tabletSpan ?? desktopSpan.clamp(1, 6);
    if (columns == 2) {
      // Compact KPI tiles share a row; wider sections stay full width.
      if (desktopSpan <= 4) return 1;
      return 2;
    }
    return columns;
  }
}
