import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/reports_center_theme.dart';

class ReportKpiItem {
  const ReportKpiItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
}

/// Responsive KPI row for individual report modules.
class ReportModuleKpiStrip extends StatelessWidget {
  const ReportModuleKpiStrip({
    super.key,
    required this.items,
    this.loading = false,
  });

  final List<ReportKpiItem> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth < 900;

        if (useWrap) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map((item) => _KpiCard(item: item, expanded: false))
                .toList(growable: false),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _KpiCard(item: items[i], expanded: true),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.item,
    required this.expanded,
  });

  final ReportKpiItem item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = item.accent ?? scheme.primary;
    final icon = item.icon ?? Icons.insights_outlined;

    return Container(
      constraints: BoxConstraints(
        minWidth: expanded ? 148 : 150,
        maxWidth: expanded ? 240 : double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ReportsCenterTheme.kpiCard(scheme, accent: accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: ReportsCenterTheme.accentWash(scheme, accent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    height: 1.05,
                    letterSpacing: -0.4,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String reportCompactCount(int value) => NumberFormat.compact().format(value);
