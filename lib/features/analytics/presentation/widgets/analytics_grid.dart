import 'package:flutter/material.dart';

/// Responsive column count for the 12-column analytics grid.
int analyticsGridColumns(double width) {
  if (width >= 1400) return 12;
  if (width >= 900) return 6;
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
    if (columns == 1 || width <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i].child,
          ],
        ],
      );
    }

    final unitWidth = (width - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in children)
          SizedBox(
            width: unitWidth * item.span(columns) + spacing * (item.span(columns) - 1),
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
    return columns;
  }
}
