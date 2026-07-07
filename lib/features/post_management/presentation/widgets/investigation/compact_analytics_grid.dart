import 'package:flutter/material.dart';

import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';

class CompactAnalyticsGrid extends StatelessWidget {
  const CompactAnalyticsGrid({
    super.key,
    required this.metrics,
    this.isDark = false,
  });

  final List<({IconData icon, String label, int value, Color? color})> metrics;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 280 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: InvestigationTheme.s8,
            crossAxisSpacing: InvestigationTheme.s8,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, i) => _MetricCell(
            icon: metrics[i].icon,
            label: metrics[i].label,
            value: compactNumber(metrics[i].value),
            color: metrics[i].color,
          ),
        );
      },
    );
  }
}

class _MetricCell extends StatefulWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  State<_MetricCell> createState() => _MetricCellState();
}

class _MetricCellState extends State<_MetricCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.color ?? scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: InvestigationTheme.animMs),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? accent.withValues(alpha: 0.08)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 13, color: accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
