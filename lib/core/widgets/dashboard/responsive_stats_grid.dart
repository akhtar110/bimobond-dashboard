import 'package:flutter/material.dart';

/// KPI card grid that wraps based on available width.
class ResponsiveStatsGrid extends StatelessWidget {
  const ResponsiveStatsGrid({
    super.key,
    required this.children,
    this.minTileWidth = 184,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / minTileWidth).floor().clamp(1, 6);
        final tileWidth =
            (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
