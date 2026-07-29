import 'package:flutter/material.dart';

import '../utils/analytics_responsive.dart';

class AnalyticsDashboardSkeleton extends StatelessWidget {
  const AnalyticsDashboardSkeleton({this.metrics, super.key});

  final AnalyticsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final hi = scheme.surfaceContainerLow;
    final gap = metrics?.sectionGap ?? 16.0;
    final headerGap = metrics?.headerGap ?? 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Flat header placeholder (no card chrome).
        _ShimmerBox(color: base, height: 40, radius: 10),
        SizedBox(height: headerGap),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 600 ? 2 : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                4,
                (_) => SizedBox(
                  width: cols == 1
                      ? c.maxWidth
                      : (c.maxWidth - 12 * (cols - 1)) / cols,
                  child: _ShimmerBox(color: base, height: 120, radius: 16),
                ),
              ),
            );
          },
        ),
        SizedBox(height: gap),
        _ShimmerBox(color: hi, height: 280, radius: 16),
        SizedBox(height: gap),
        _ShimmerBox(color: hi, height: 280, radius: 16),
        SizedBox(height: gap),
        LayoutBuilder(
          builder: (context, c) {
            final sideBySide = c.maxWidth >= 900;
            if (!sideBySide) {
              return Column(
                children: [
                  _ShimmerBox(color: base, height: 240, radius: 16),
                  SizedBox(height: gap),
                  _ShimmerBox(color: base, height: 240, radius: 16),
                ],
              );
            }
            final half = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: half,
                  child: _ShimmerBox(color: base, height: 240, radius: 16),
                ),
                SizedBox(
                  width: half,
                  child: _ShimmerBox(color: base, height: 240, radius: 16),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.color,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hi = scheme.surfaceContainerLowest;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final c = Color.lerp(widget.color, hi, _ctrl.value)!;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: scheme.outlineVariant),
          ),
        );
      },
    );
  }
}
