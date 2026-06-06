import 'package:flutter/material.dart';

import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';

class CompactAnalyticsGrid extends StatelessWidget {
  const CompactAnalyticsGrid({
    super.key,
    required this.metrics,
    required this.isDark,
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
            isDark: isDark,
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
    required this.isDark,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  @override
  State<_MetricCell> createState() => _MetricCellState();
}

class _MetricCellState extends State<_MetricCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;
    final bg = widget.isDark
        ? const Color(0xFF0F1421)
        : const Color(0xFFF8FAFC);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: InvestigationTheme.animMs),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? accent.withValues(alpha: 0.06) : bg,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.35)
                : (widget.isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0)),
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
                      color: InvestigationTheme.mutedText(context, widget.isDark),
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
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
