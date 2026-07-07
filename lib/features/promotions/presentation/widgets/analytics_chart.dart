import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/promotion_overview_entity.dart';
import 'promotions_dashboard_widgets.dart';

class AnalyticsChartCard extends StatelessWidget {
  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.chartHeight = 160,
    this.expandChild = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final double? chartHeight;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DashboardCard(
      padding: const EdgeInsets.all(PromotionsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, size: 18, color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PromotionsSpace.lg),
          if (expandChild || chartHeight == null)
            child
          else
            SizedBox(height: chartHeight, child: child),
        ],
      ),
    );
  }
}

class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({super.key, required this.overview});

  final PromotionOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = [
      FlSpot(0, overview.totalSpentCoins * 0.4),
      FlSpot(1, overview.totalSpentCoins * 0.55),
      FlSpot(2, overview.totalSpentCoins * 0.68),
      FlSpot(3, overview.totalSpentCoins * 0.82),
      FlSpot(4, overview.totalSpentCoins),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, _) => Text(
                CoinFormat.coinsAmount(value),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignStatusItem {
  const _CampaignStatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class CampaignStatusChart extends StatelessWidget {
  const CampaignStatusChart({super.key, required this.overview});

  final PromotionOverviewEntity overview;

  List<_CampaignStatusItem> _items(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    return [
      _CampaignStatusItem(
        label: l10n.t('promoStatusActive'),
        value: overview.activeCampaigns,
        color: scheme.primary,
      ),
      _CampaignStatusItem(
        label: l10n.t('promoStatusPendingPayment'),
        value: overview.pendingPaymentCampaigns,
        color: scheme.tertiary,
      ),
      _CampaignStatusItem(
        label: l10n.t('promoStatusPaused'),
        value: overview.pausedCampaigns,
        color: scheme.secondary,
      ),
      _CampaignStatusItem(
        label: l10n.t('promoStatusCompleted'),
        value: overview.completedCampaigns,
        color: scheme.outline,
      ),
      _CampaignStatusItem(
        label: l10n.t('promoStatusRejected'),
        value: overview.rejectedCampaigns,
        color: scheme.error,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final items = _items(context, scheme);
    final total = overview.totalCampaigns;
    final pieItems = items.where((item) => item.value > 0).toList();

    if (total <= 0) {
      return _ChartEmptyState(message: l10n.t('noData'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 380;

        final donut = SizedBox(
          width: stacked ? 168 : 156,
          height: stacked ? 168 : 156,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: stacked ? 46 : 42,
                  startDegreeOffset: -90,
                  sections: pieItems
                      .map(
                        (item) => PieChartSectionData(
                          value: item.value.toDouble(),
                          color: item.color,
                          radius: stacked ? 28 : 26,
                          showTitle: false,
                        ),
                      )
                      .toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('promoMetricTotalCampaigns'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          height: 1.1,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );

        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CampaignStatusLegendRow(
                item: items[i],
                total: total,
              ),
            ],
          ],
        );

        if (stacked) {
          return Column(
            children: [
              donut,
              const SizedBox(height: PromotionsSpace.lg),
              legend,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            donut,
            const SizedBox(width: PromotionsSpace.lg),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _CampaignStatusLegendRow extends StatelessWidget {
  const _CampaignStatusLegendRow({
    required this.item,
    required this.total,
  });

  final _CampaignStatusItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = total > 0 ? (item.value / total).clamp(0.0, 1.0) : 0.0;
    final percentLabel = NumberFormat('#0.#').format(percent * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.value > 0
                    ? item.color
                    : scheme.outlineVariant.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.value > 0
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ),
            Text(
              '${item.value}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(
                '$percentLabel%',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: scheme.surfaceContainerHighest,
            color: item.color,
          ),
        ),
      ],
    );
  }
}

class ImpressionGrowthChart extends StatelessWidget {
  const ImpressionGrowthChart({super.key, required this.overview});

  final PromotionOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final compact = NumberFormat.compact();
    final percent = NumberFormat('#0.##');

    final last24 = overview.impressionsLast24Hours;
    final total = overview.totalImpressions;
    final share = total > 0 ? (last24 / total).clamp(0.0, 1.0) : 0.0;

    if (total <= 0 && last24 <= 0) {
      return _ChartEmptyState(message: l10n.t('noData'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;

        final last24Card = _ImpressionMetricCard(
          label: l10n.t('promoMetricImpressions24h'),
          value: compact.format(last24),
          icon: Icons.trending_up_rounded,
          accent: scheme.primary,
          highlighted: true,
        );
        final totalCard = _ImpressionMetricCard(
          label: l10n.t('promoImpressions'),
          value: compact.format(total),
          icon: Icons.visibility_outlined,
          accent: scheme.secondary,
        );

        final metricRow = wide
            ? Row(
                children: [
                  Expanded(child: last24Card),
                  const SizedBox(width: PromotionsSpace.md),
                  Expanded(child: totalCard),
                ],
              )
            : Column(
                children: [
                  last24Card,
                  const SizedBox(height: PromotionsSpace.sm),
                  totalCard,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            metricRow,
            const SizedBox(height: PromotionsSpace.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(PromotionsSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('promoImpressionGrowth'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${percent.format(share * 100)}%',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PromotionsSpace.md),
                    SizedBox(
                      height: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: [
                            if (share > 0)
                              Expanded(
                                flex: (share * 1000).round().clamp(1, 1000),
                                child: ColoredBox(color: scheme.primary),
                              ),
                            if (share < 1)
                              Expanded(
                                flex: ((1 - share) * 1000).round().clamp(1, 1000),
                                child: ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: PromotionsSpace.md),
                    SizedBox(
                      height: 120,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: total > 0 ? total.toDouble() : last24.toDouble(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: total > 0 ? total / 4 : null,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: scheme.outlineVariant.withValues(alpha: 0.25),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == meta.max || value == meta.min) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    compact.format(value),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  final label = switch (value.toInt()) {
                                    0 => l10n.t('promoMetricImpressions24h'),
                                    1 => l10n.t('promoImpressions'),
                                    _ => '',
                                  };
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: last24.toDouble(),
                                  width: wide ? 56 : 40,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      scheme.primary,
                                      scheme.primary.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: total.toDouble(),
                                  width: wide ? 56 : 40,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  color: scheme.secondaryContainer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: PromotionsSpace.sm),
                    Row(
                      children: [
                        _ImpressionLegendDot(
                          color: scheme.primary,
                          label: l10n.t('promoMetricImpressions24h'),
                        ),
                        const SizedBox(width: PromotionsSpace.lg),
                        _ImpressionLegendDot(
                          color: scheme.secondaryContainer,
                          label: l10n.t('promoImpressions'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImpressionMetricCard extends StatelessWidget {
  const _ImpressionMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? accent.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PromotionsSpace.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpressionLegendDot extends StatelessWidget {
  const _ImpressionLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PromotionsSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 32,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
            const SizedBox(height: PromotionsSpace.sm),
            Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
