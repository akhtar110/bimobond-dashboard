import 'package:flutter/material.dart';

import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';

class EngagementMetricCards extends StatelessWidget {
  const EngagementMetricCards({super.key, required this.metrics});

  final List<({IconData icon, String label, int value, Color accent})> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 520
            ? 3
            : constraints.maxWidth >= 320
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: InvestigationTheme.s8,
            crossAxisSpacing: InvestigationTheme.s8,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, i) {
            final m = metrics[i];
            return _MetricCard(
              icon: m.icon,
              label: m.label,
              value: compactNumber(m.value),
              accent: m.accent,
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: InvestigationTheme.animMs),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.accent.withValues(alpha: 0.08)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 14, color: widget.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 18,
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
