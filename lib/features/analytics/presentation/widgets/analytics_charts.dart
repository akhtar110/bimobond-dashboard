import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/analytics_format.dart';

class AnalyticsMultiLineChart extends StatelessWidget {
  const AnalyticsMultiLineChart({
    super.key,
    required this.series,
    this.height = 240,
  });

  final List<AnalyticsLineSeries> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (series.every((s) => s.points.isEmpty)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            context.l10n.t('analyticsNoDataForPeriod'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxLen = series.map((s) => s.points.length).reduce((a, b) => a > b ? a : b);
    final maxY = series
        .expand((s) => s.points)
        .fold<double>(0, (m, p) => p.$2 > m ? p.$2 : m);
    final yMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final s in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AnalyticsChartColors.grid(scheme),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      AnalyticsFormat.count(v),
                      style: TextStyle(
                        fontSize: 10,
                        color: AnalyticsChartColors.axisLabel(scheme),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (maxLen / 5).clamp(1, maxLen.toDouble()),
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      final points = series.firstWhere((s) => s.points.isNotEmpty,
                          orElse: () => series.first).points;
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AnalyticsFormat.shortDate(points[idx].$1),
                          style: TextStyle(
                            fontSize: 9,
                            color: AnalyticsChartColors.axisLabel(scheme),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final s = series[spot.barIndex];
                    final date = s.points[spot.spotIndex].$1;
                    return LineTooltipItem(
                      '${s.label}\n${AnalyticsFormat.shortDate(date)}: ${AnalyticsFormat.count(spot.y)}',
                      TextStyle(
                        color: scheme.onInverseSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                for (final s in series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.points.length; i++)
                        FlSpot(i.toDouble(), s.points[i].$2),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.22,
                    color: s.color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: s.color.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 450),
          ),
        ),
      ],
    );
  }
}

class AnalyticsLineSeries {
  const AnalyticsLineSeries({
    required this.label,
    required this.color,
    required this.points,
  });

  final String label;
  final Color color;
  final List<(DateTime date, double value)> points;
}

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    super.key,
    required this.entries,
    this.horizontal = false,
    this.height = 200,
  });

  final List<AnalyticsBarEntry> entries;
  final bool horizontal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(context.l10n.t('analyticsNoData'),
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    final maxY = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final yMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    if (horizontal) {
      return SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AnalyticsChartColors.grid(scheme),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 88,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        entries[idx].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: [
              for (var i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value,
                      color: entries[i].color ?? scheme.primary,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 450),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AnalyticsChartColors.grid(scheme),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  AnalyticsFormat.count(v),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[idx].label,
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value,
                    color: entries[i].color ?? scheme.primary,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
        swapAnimationDuration: const Duration(milliseconds: 450),
      ),
    );
  }
}

class AnalyticsBarEntry {
  const AnalyticsBarEntry({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

class AnalyticsPieChart extends StatelessWidget {
  const AnalyticsPieChart({
    super.key,
    required this.entries,
    this.donut = false,
    this.size = 180,
  });

  final List<AnalyticsPieEntry> entries;
  final bool donut;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(context.l10n.t('analyticsNoData'),
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    return SizedBox(
      height: size,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: donut ? 42 : 0,
                sections: [
                  for (final e in entries)
                    if (e.value > 0)
                      PieChartSectionData(
                        value: e.value,
                        color: e.color,
                        title: '${((e.value / total) * 100).round()}%',
                        radius: 52,
                        titleStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 450),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in entries)
                  if (e.value > 0) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          AnalyticsFormat.count(e.value),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsPieEntry {
  const AnalyticsPieEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}
