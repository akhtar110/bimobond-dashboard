import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/localization.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 12.0 : 16.0;
    final sectionGap = width < 900 ? 16.0 : 20.0;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontal,
              12,
              horizontal,
              16,
            ),
            children: [
              _buildStatsGrid(context),
              SizedBox(height: sectionGap),
              _ChartCard(
                title: l10n.t('userGrowth'),
                icon: Icons.trending_up_rounded,
              ),
              _ChartCard(
                title: l10n.t('videoUploads'),
                icon: Icons.video_call_rounded,
              ),
              _ChartCard(
                title: l10n.t('reportsTrend'),
                icon: Icons.report_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final l10n = context.l10n;

    final stats = [
      _StatItem(l10n.t('totalUsers'), '128.6K', Icons.people_alt_rounded),
      _StatItem(l10n.t('activeUsersToday'), '32.4K', Icons.person_pin_circle),
      _StatItem(l10n.t('totalVideos'), '3.9M', Icons.video_library_rounded),
      _StatItem(l10n.t('videosToday'), '12.8K', Icons.ondemand_video_rounded),
      _StatItem(l10n.t('pendingReports'), '138', Icons.report_gmailerrorred),
      _StatItem(l10n.t('bannedUsers'), '1,206', Icons.block_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 600;

        int crossAxisCount = 2;
        if (width > 1400) {
          crossAxisCount = 6;
        } else if (width > 1100) {
          crossAxisCount = 4;
        } else if (width > 720) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: compact ? 10 : 12,
            crossAxisSpacing: compact ? 10 : 12,
            mainAxisExtent: compact ? 132 : 148,
          ),
          itemBuilder: (_, index) => _StatCard(
            item: stats[index],
            compact: compact,
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;

  _StatItem(this.title, this.value, this.icon);
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item, this.compact = false});

  final _StatItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: compact ? 18 : 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '12%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 900;

    return Container(
      margin: EdgeInsetsDirectional.only(bottom: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              final periodChip = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.tOr('analyticsLast7Days', 'Last 7 days'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );

              final titleRow = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (!stacked) periodChip,
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: periodChip,
                    ),
                  ],
                );
              }
              return titleRow;
            },
          ),
          SizedBox(height: compact ? 16 : 20),
          SizedBox(
            height: compact ? 220 : 260,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (spots) => spots
                        .map(
                          (e) => LineTooltipItem(
                            '${e.y.toStringAsFixed(1)}',
                            theme.textTheme.bodyMedium!,
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.22),
                          scheme.tertiary.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: scheme.surface,
                        strokeWidth: 3,
                        strokeColor: scheme.primary,
                      ),
                    ),
                    spots: const [
                      FlSpot(0, 1.5),
                      FlSpot(1, 2.8),
                      FlSpot(2, 2.2),
                      FlSpot(3, 3.8),
                      FlSpot(4, 3.2),
                      FlSpot(5, 4.6),
                      FlSpot(6, 4.1),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
