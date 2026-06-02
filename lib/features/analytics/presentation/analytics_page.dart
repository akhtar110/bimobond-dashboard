import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/localization.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsetsDirectional.all(16),
      children: [
        _BarCard(title: l10n.t('dau')),
        _BarCard(title: l10n.t('engagementRate')),
        _BarCard(title: l10n.t('mostReportedContent')),
        _BarCard(title: l10n.t('mostActiveUsers')),
      ],
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(
                    5,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(toY: (index + 1) * 3.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
