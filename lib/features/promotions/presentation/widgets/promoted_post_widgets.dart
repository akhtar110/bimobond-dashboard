import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/promoted_posts_bloc.dart';
import 'analytics_chart.dart';
import '../utils/promotions_responsive.dart';
import 'promotions_dashboard_widgets.dart';
import 'promotions_data_display_widgets.dart';
import 'promotions_shared_widgets.dart';

String _formatCampaignDateRange(
  AppLocalizations l10n,
  DateFormat dateFmt,
  DateTime? start,
  DateTime? end,
) {
  if (start != null && end != null) {
    return '${dateFmt.format(start)} – ${dateFmt.format(end)}';
  }
  if (start != null) {
    return '${l10n.t('startDate')}: ${dateFmt.format(start)}';
  }
  return '${l10n.t('endDate')}: ${dateFmt.format(end!)}';
}

class AnalyticsMetricCard extends StatelessWidget {
  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = promotionsMetricsOf(context);
    return DashboardCard(
      padding: EdgeInsets.all(metrics.metricCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: metrics.isMobile ? 16 : 18, color: scheme.primary),
            SizedBox(height: metrics.isMobile ? 4 : PromotionsSpace.sm),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: metrics.isMobile ? 11 : null,
                ),
          ),
          SizedBox(height: metrics.isMobile ? 4 : 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  fontSize: metrics.isMobile ? 18 : null,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class PromotionKpiGrid extends StatelessWidget {
  const PromotionKpiGrid({
    super.key,
    required this.stats,
    this.compact = false,
  });

  final PostPromotionStatsEntity stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PromotionAnalyticsKpiStrip(stats: stats);
    }
    final l10n = context.l10n;
    final compactFmt = NumberFormat.compact();
    final percent = NumberFormat('#0.##');
    final s = stats.statistics;
    final p = stats.promotion;

    final metrics = [
      (l10n.t('promoMetricViews'), compactFmt.format(s.views), Icons.visibility_outlined),
      (l10n.t('promoMetricLikes'), compactFmt.format(s.likes), Icons.favorite_outline),
      (l10n.t('promoMetricComments'), compactFmt.format(s.comments), Icons.chat_bubble_outline),
      (l10n.t('promoMetricShares'), compactFmt.format(s.shares), Icons.share_outlined),
      (l10n.t('promoMetricSaves'), compactFmt.format(s.saves), Icons.bookmark_outline),
      (l10n.t('promoMetricReposts'), compactFmt.format(s.reposts), Icons.repeat),
      (l10n.t('promoImpressions'), compactFmt.format(s.promotedImpressions), Icons.ads_click_outlined),
      (l10n.t('promoMetricUniqueViewers'), compactFmt.format(s.uniquePromotedViewers), Icons.people_outline),
      (l10n.t('promoMetricFollowersGained'), compactFmt.format(s.followersGained), Icons.person_add_outlined),
      (l10n.t('promoMetricPromotionSpend'), CoinFormat.coins(s.promotionSpendCoins), Icons.payments_outlined),
      (l10n.t('promoMetricCostPerImpression'), CoinFormat.coins(s.costPerImpression), Icons.price_change_outlined),
      (l10n.t('promoMetricCostPerView'), CoinFormat.coins(s.costPerView), Icons.trending_down_outlined),
      (l10n.t('promoMetricEngagementRate'), '${percent.format(s.engagementRate)}%', Icons.insights_outlined),
      (l10n.t('promoMetricTotalEngagements'), compactFmt.format(s.totalEngagements), Icons.bolt_outlined),
      (l10n.t('promoMetricActiveCampaigns'), compactFmt.format(p.activeCampaigns), Icons.campaign_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= PromotionsBreakpoints.largeDesktop
            ? 5
            : constraints.maxWidth >= PromotionsBreakpoints.smallDesktop
                ? 4
                : constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 480
                        ? 2
                        : 1;
        final gap = promotionsMetricsOf(context).isMobile
            ? PromotionsSpace.md
            : PromotionsSpace.lg;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: crossCount == 1 ? 2.2 : 1.55,
          ),
          itemBuilder: (context, index) {
            final m = metrics[index];
            return AnalyticsMetricCard(
              label: m.$1,
              value: m.$2,
              icon: m.$3,
            );
          },
        );
      },
    );
  }
}

class PromotionImpressionChart extends StatelessWidget {
  const PromotionImpressionChart({
    super.key,
    required this.buckets,
    this.title,
  });

  final List<ImpressionDayBucketEntity> buckets;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.MMMd();

    if (buckets.isEmpty) {
      return AnalyticsChartCard(
        title: title ?? l10n.t('promoImpressions7Day'),
        child: Center(
          child: Text(
            l10n.t('noData'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxY = buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);
    final spots = buckets.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return AnalyticsChartCard(
      title: title ?? l10n.t('promoImpressions7Day'),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 1 : maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
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
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                  final parsed = DateTime.tryParse(buckets[i].date);
                  final label = parsed != null ? dateFmt.format(parsed) : buckets[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.toInt();
                final date = i >= 0 && i < buckets.length ? buckets[i].date : '';
                return LineTooltipItem(
                  '$date\n${s.y.toInt()}',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                  radius: 4,
                  color: scheme.primary,
                  strokeWidth: 2,
                  strokeColor: scheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PromotedPostPreviewCard extends StatelessWidget {
  const PromotedPostPreviewCard({
    super.key,
    required this.post,
    this.compact = false,
  });

  final PromotedPostSummaryEntity post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final compactFmt = NumberFormat.compact();

    return DashboardCard(
      padding: const EdgeInsets.all(PromotionsSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: compact ? 80 : 112,
              height: compact ? 106 : 148,
              child: post.previewThumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: post.previewThumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.videocam_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.videocam_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: PromotionsSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (post.isAd)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.t('promoAdBadge'),
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (post.status != null && post.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.status!,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: PromotionsSpace.sm),
                Text(
                  post.description?.trim().isNotEmpty == true
                      ? post.description!.trim()
                      : l10n.t('noDescription'),
                  maxLines: compact ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                if (post.creatorUsername != null || post.creatorFullName != null) ...[
                  const SizedBox(height: PromotionsSpace.sm),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '@${post.creatorUsername ?? post.creatorFullName ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: PromotionsSpace.md),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.visibility_outlined,
                      label: compactFmt.format(post.viewCount),
                    ),
                    _MetaChip(
                      icon: Icons.favorite_outline,
                      label: compactFmt.format(post.likeCount),
                    ),
                    _MetaChip(
                      icon: Icons.chat_bubble_outline,
                      label: compactFmt.format(post.commentCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class PrimaryCampaignCard extends StatelessWidget {
  const PrimaryCampaignCard({super.key, required this.campaign});

  final PrimaryCampaignEntity campaign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final percent = NumberFormat('#0.#');
    final dateFmt = DateFormat.yMMMd();
    final progress = campaign.progress?.progressPercent ?? campaign.progressPercent;

    return DashboardCard(
      padding: const EdgeInsets.all(PromotionsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.star_rounded, color: scheme.primary, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.t('promoPrimaryCampaign'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              CampaignStatusBadge(status: campaign.status),
            ],
          ),
          const SizedBox(height: PromotionsSpace.md),
          Text(
            campaign.objective,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (campaign.startAt != null || campaign.endAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatCampaignDateRange(l10n, dateFmt, campaign.startAt, campaign.endAt),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: PromotionsSpace.md),
          _StatRow(
            label: l10n.t('promoBudget'),
            value: CoinFormat.coins(campaign.budgetCoins),
          ),
          _StatRow(
            label: l10n.t('promoSpent'),
            value: CoinFormat.coins(campaign.spentCoins),
          ),
          _StatRow(
            label: l10n.t('promoImpressions'),
            value:
                '${campaign.impressionCount} / ${campaign.impressionTarget}',
          ),
          const SizedBox(height: PromotionsSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${percent.format(progress)}% ${l10n.t('promoProgress')}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class PromotionAnalyticsKpiStrip extends StatelessWidget {
  const PromotionAnalyticsKpiStrip({super.key, required this.stats});

  final PostPromotionStatsEntity stats;

  static const _stripHeight = 44.0;
  static const _minTileWidth = 108.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = NumberFormat.compact();
    final percent = NumberFormat('#0.##');
    final s = stats.statistics;
    final p = stats.promotion;

    final items = [
      (l10n.t('promoMetricViews'), compact.format(s.views), Icons.visibility_outlined),
      (l10n.t('promoMetricLikes'), compact.format(s.likes), Icons.favorite_outline),
      (l10n.t('promoImpressions'), compact.format(s.promotedImpressions), Icons.ads_click_outlined),
      (l10n.t('promoMetricPromotionSpend'), CoinFormat.coins(s.promotionSpendCoins), Icons.payments_outlined),
      (l10n.t('promoMetricEngagementRate'), '${percent.format(s.engagementRate)}%', Icons.insights_outlined),
      (l10n.t('promoMetricActiveCampaigns'), compact.format(p.activeCampaigns), Icons.campaign_outlined),
      (l10n.t('promoMetricFollowersGained'), compact.format(s.followersGained), Icons.person_add_outlined),
      (l10n.t('promoMetricCostPerImpression'), CoinFormat.coins(s.costPerImpression), Icons.price_change_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fitsInRow =
            width >= _minTileWidth * items.length + 8 * (items.length - 1);

        if (fitsInRow) {
          return SizedBox(
            height: _stripHeight,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: PromotionsSpace.sm),
                  Expanded(
                    child: _AnalyticsKpiTile(
                      label: items[i].$1,
                      value: items[i].$2,
                      icon: items[i].$3,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return SizedBox(
          height: _stripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: PromotionsSpace.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: _minTileWidth,
                child: _AnalyticsKpiTile(
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AnalyticsKpiTile extends StatelessWidget {
  const _AnalyticsKpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          height: 1.1,
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

const double kPromotedPostsTableHeaderHeight = kPromotionsDataTableHeaderHeight;
const double kCampaignHistoryHeaderHeight = 40;
const double _kCellHPad = 10;
const double _kRowVPad = 10;

enum PromotedPostsTableDensity { wide, medium, narrow, compact }

PromotedPostsTableDensity promotedPostsTableDensityForWidth(double width) {
  if (width >= 1180) return PromotedPostsTableDensity.wide;
  if (width >= 880) return PromotedPostsTableDensity.medium;
  if (width >= 640) return PromotedPostsTableDensity.narrow;
  return PromotedPostsTableDensity.compact;
}

bool promotedPostsUseCompactCards(PromotedPostsTableDensity density) =>
    density == PromotedPostsTableDensity.compact;

double promotedPostsTableRowHeight(PromotedPostsTableDensity density) {
  return switch (density) {
    PromotedPostsTableDensity.wide => 72,
    PromotedPostsTableDensity.medium => 68,
    PromotedPostsTableDensity.narrow => 56,
    PromotedPostsTableDensity.compact => 0,
  };
}

double promotedPostsTableMinWidth(PromotedPostsTableDensity density) {
  return switch (density) {
    PromotedPostsTableDensity.wide => 1120,
    PromotedPostsTableDensity.medium => 920,
    PromotedPostsTableDensity.narrow => 620,
    PromotedPostsTableDensity.compact => 0,
  };
}

double promotedPostsThumbSize(PromotedPostsTableDensity density) {
  return switch (density) {
    PromotedPostsTableDensity.wide => 46,
    PromotedPostsTableDensity.medium => 42,
    PromotedPostsTableDensity.narrow => 38,
    PromotedPostsTableDensity.compact => 52,
  };
}

enum CampaignHistoryDensity { wide, medium, narrow }

CampaignHistoryDensity campaignHistoryDensityForWidth(double width) {
  if (width >= 1100) return CampaignHistoryDensity.wide;
  if (width >= 820) return CampaignHistoryDensity.medium;
  return CampaignHistoryDensity.narrow;
}

class CampaignHistoryTable extends StatelessWidget {
  const CampaignHistoryTable({
    super.key,
    required this.campaigns,
    required this.onOpenCampaign,
    required this.onPause,
    required this.onActivate,
    required this.onReject,
    this.isActioning = false,
  });

  final List<CampaignHistoryItemEntity> campaigns;
  final ValueChanged<String> onOpenCampaign;
  final ValueChanged<String> onPause;
  final ValueChanged<String> onActivate;
  final ValueChanged<String> onReject;
  final bool isActioning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (campaigns.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PromotionsSpace.lg),
          child: Center(child: Text(l10n.t('noData'))),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = campaignHistoryDensityForWidth(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('promoCampaignHistory'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: PromotionsSpace.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CampaignHistoryHeader(density: density),
                    for (var i = 0; i < campaigns.length; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == campaigns.length - 1
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                        ),
                        child: _CampaignHistoryRow(
                          campaign: campaigns[i],
                          density: density,
                          isActioning: isActioning,
                          onOpenCampaign: () => onOpenCampaign(campaigns[i].id),
                          onPause: () => onPause(campaigns[i].id),
                          onActivate: () => onActivate(campaigns[i].id),
                          onReject: () => onReject(campaigns[i].id),
                        ),
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

class _CampaignHistoryHeader extends StatelessWidget {
  const _CampaignHistoryHeader({required this.density});

  final CampaignHistoryDensity density;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 11,
        );

    return Container(
      height: kCampaignHistoryHeaderHeight,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _CampaignHistoryRowLayout(
        density: density,
        id: Text(l10n.t('promoPackage'), style: style),
        status: Text(l10n.t('status'), style: style),
        objective: Text(l10n.t('promoObjective'), style: style),
        budget: density != CampaignHistoryDensity.narrow
            ? Text(l10n.t('promoBudget'), style: style)
            : const SizedBox.shrink(),
        spent: density == CampaignHistoryDensity.wide
            ? Text(l10n.t('promoSpent'), style: style)
            : const SizedBox.shrink(),
        impressions: density != CampaignHistoryDensity.narrow
            ? Text(l10n.t('promoImpressions'), style: style)
            : const SizedBox.shrink(),
        progress: Text(l10n.t('promoProgress'), style: style),
        startDate: density == CampaignHistoryDensity.wide
            ? Text(l10n.t('startDate'), style: style)
            : const SizedBox.shrink(),
        endDate: density == CampaignHistoryDensity.wide
            ? Text(l10n.t('endDate'), style: style)
            : const SizedBox.shrink(),
        actions: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CampaignHistoryRow extends StatelessWidget {
  const _CampaignHistoryRow({
    required this.campaign,
    required this.density,
    required this.isActioning,
    required this.onOpenCampaign,
    required this.onPause,
    required this.onActivate,
    required this.onReject,
  });

  final CampaignHistoryItemEntity campaign;
  final CampaignHistoryDensity density;
  final bool isActioning;
  final VoidCallback onOpenCampaign;
  final VoidCallback onPause;
  final VoidCallback onActivate;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd();
    final percent = NumberFormat('#0.#');
    final progress = c.progress?.progressPercent ?? c.progressPercent;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
        );
    final numericStyle = cellStyle?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onOpenCampaign,
        hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: _kRowVPad,
          ),
          child: _CampaignHistoryRowLayout(
            density: density,
            id: Text(
              c.packageName?.trim().isNotEmpty == true
                  ? c.packageName!.trim()
                  : l10n.t('notAvailable'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            status: CampaignStatusBadge(status: c.status),
            objective: Text(
              c.objective,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
            budget: density != CampaignHistoryDensity.narrow
                ? Text(
                    CoinFormat.coins(c.budgetCoins),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: numericStyle,
                  )
                : const SizedBox.shrink(),
            spent: density == CampaignHistoryDensity.wide
                ? Text(
                    CoinFormat.coins(c.spentCoins),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: numericStyle,
                  )
                : const SizedBox.shrink(),
            impressions: density != CampaignHistoryDensity.narrow
                ? Text(
                    '${c.impressionCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: numericStyle,
                  )
                : const SizedBox.shrink(),
            progress: Text(
              '${percent.format(progress)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: numericStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            startDate: density == CampaignHistoryDensity.wide
                ? Text(
                    c.startAt != null ? dateFmt.format(c.startAt!) : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                  )
                : const SizedBox.shrink(),
            endDate: density == CampaignHistoryDensity.wide
                ? Text(
                    c.endAt != null ? dateFmt.format(c.endAt!) : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                  )
                : const SizedBox.shrink(),
            actions: _CampaignHistoryActions(
              status: c.status,
              isActioning: isActioning,
              onOpen: onOpenCampaign,
              onPause: onPause,
              onActivate: onActivate,
              onReject: onReject,
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignHistoryRowLayout extends StatelessWidget {
  const _CampaignHistoryRowLayout({
    required this.density,
    required this.id,
    required this.status,
    required this.objective,
    required this.budget,
    required this.spent,
    required this.impressions,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.actions,
  });

  final CampaignHistoryDensity density;
  final Widget id;
  final Widget status;
  final Widget objective;
  final Widget budget;
  final Widget spent;
  final Widget impressions;
  final Widget progress;
  final Widget startDate;
  final Widget endDate;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final showBudget = density != CampaignHistoryDensity.narrow;
    final showSpent = density == CampaignHistoryDensity.wide;
    final showImpressions = density != CampaignHistoryDensity.narrow;
    final showDates = density == CampaignHistoryDensity.wide;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _cell(id)),
        Expanded(flex: 2, child: _cell(status)),
        Expanded(flex: 2, child: _cell(objective)),
        if (showBudget) Expanded(flex: 1, child: _cell(budget, alignEnd: true)),
        if (showSpent) Expanded(flex: 1, child: _cell(spent, alignEnd: true)),
        if (showImpressions)
          Expanded(flex: 1, child: _cell(impressions, alignEnd: true)),
        Expanded(flex: 1, child: _cell(progress, alignEnd: true)),
        if (showDates) Expanded(flex: 2, child: _cell(startDate)),
        if (showDates) Expanded(flex: 2, child: _cell(endDate)),
        SizedBox(width: 40, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _CampaignHistoryActions extends StatelessWidget {
  const _CampaignHistoryActions({
    required this.status,
    required this.isActioning,
    required this.onOpen,
    required this.onPause,
    required this.onActivate,
    required this.onReject,
  });

  final String status;
  final bool isActioning;
  final VoidCallback onOpen;
  final VoidCallback onPause;
  final VoidCallback onActivate;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final parsed = CampaignStatus.tryParse(status);

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      padding: EdgeInsets.zero,
      iconSize: 20,
      enabled: !isActioning,
      onSelected: (value) {
        switch (value) {
          case 'open':
            onOpen();
          case 'pause':
            onPause();
          case 'activate':
            onActivate();
          case 'reject':
            onReject();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              const Icon(Icons.open_in_new_rounded, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoOpenCampaign')),
            ],
          ),
        ),
        if (parsed == CampaignStatus.active)
          PopupMenuItem(
            value: 'pause',
            child: Row(
              children: [
                const Icon(Icons.pause_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text(l10n.t('promoPause')),
              ],
            ),
          ),
        if (parsed == CampaignStatus.paused)
          PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text(l10n.t('promoActivate')),
              ],
            ),
          ),
        if (parsed != CampaignStatus.rejected)
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.block, size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Text(l10n.t('promoReject')),
              ],
            ),
          ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

class PromotedPostsTable extends StatelessWidget {
  const PromotedPostsTable({
    super.key,
    required this.posts,
    required this.sortField,
    required this.onSort,
    required this.onViewAnalytics,
    required this.onViewHistory,
  });

  final List<PromotedPostEntity> posts;
  final PromotedPostsSortField sortField;
  final ValueChanged<PromotedPostsSortField> onSort;
  final ValueChanged<String> onViewAnalytics;
  final ValueChanged<String> onViewHistory;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final density =
            promotedPostsTableDensityForWidth(constraints.maxWidth);
        final scheme = Theme.of(context).colorScheme;

        if (promotedPostsUseCompactCards(density)) {
          return DecoratedBox(
            decoration: promotionsInnerTableDecoration(scheme),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < posts.length; i++) ...[
                    _PromotedPostCompactCard(
                      row: posts[i],
                      onViewAnalytics: () => onViewAnalytics(posts[i].post.id),
                      onViewHistory: () => onViewHistory(posts[i].post.id),
                    ),
                    if (i < posts.length - 1)
                      Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                  ],
                ],
              ),
            ),
          );
        }

        final minWidth = promotedPostsTableMinWidth(density);
        final tableWidth = constraints.maxWidth >= minWidth
            ? constraints.maxWidth
            : minWidth;

        Widget table = DecoratedBox(
          decoration: promotionsInnerTableDecoration(scheme),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: tableWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PromotedPostsTableHeader(
                    density: density,
                    sortField: sortField,
                    onSort: onSort,
                  ),
                  for (var i = 0; i < posts.length; i++) ...[
                    _PromotedPostsTableRow(
                      row: posts[i],
                      density: density,
                      striped: i.isOdd,
                      onViewAnalytics: () => onViewAnalytics(posts[i].post.id),
                      onViewHistory: () => onViewHistory(posts[i].post.id),
                    ),
                    if (i < posts.length - 1)
                      Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );

        if (constraints.maxWidth < minWidth) {
          table = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: table,
          );
        }

        return table;
      },
    );
  }
}

class _PromotedPostPrimaryCell extends StatelessWidget {
  const _PromotedPostPrimaryCell({
    required this.primary,
    required this.density,
    required this.cellStyle,
    required this.percent,
    required this.scheme,
  });

  final PrimaryCampaignEntity? primary;
  final PromotedPostsTableDensity density;
  final TextStyle? cellStyle;
  final NumberFormat percent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (primary == null) {
      return Text(
        '—',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    final progressLabel = '${percent.format(primary!.progressPercent)}%';

    if (density == PromotedPostsTableDensity.wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CampaignStatusBadge(status: primary!.status),
          const SizedBox(height: 4),
          Text(
            primary!.objective,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            progressLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CampaignStatusBadge(status: primary!.status),
            Text(
              progressLabel,
              style: TextStyle(
                fontSize: 11,
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          primary!.objective,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PromotedPostCompactCard extends StatelessWidget {
  const _PromotedPostCompactCard({
    required this.row,
    required this.onViewAnalytics,
    required this.onViewHistory,
  });

  final PromotedPostEntity row;
  final VoidCallback onViewAnalytics;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = NumberFormat.compact();
    final percent = NumberFormat('#0.##');
    final primary = row.primaryCampaign;
    final thumbSize = promotedPostsThumbSize(PromotedPostsTableDensity.compact);

    Widget statChip(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onViewAnalytics,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: _PostThumbnail(post: row.post),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.post.description?.trim().isNotEmpty == true
                              ? row.post.description!.trim()
                              : l10n.t('noDescription'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.post.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _PromotedPostRowActions(
                    onViewAnalytics: onViewAnalytics,
                    onViewHistory: onViewHistory,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  statChip(
                    l10n.t('promoMetricViews'),
                    compact.format(row.statistics.views),
                  ),
                  statChip(
                    l10n.t('promoMetricLikes'),
                    compact.format(row.statistics.likes),
                  ),
                  statChip(
                    l10n.t('promoImpressions'),
                    compact.format(row.promotion.totalImpressions),
                  ),
                  statChip(
                    l10n.t('promoSpent'),
                    CoinFormat.coins(row.promotion.totalSpentCoins),
                  ),
                  statChip(
                    l10n.t('promoMetricEngagementRate'),
                    '${percent.format(row.statistics.engagementRate)}%',
                  ),
                  statChip(
                    l10n.t('promoCampaignCount'),
                    '${row.promotion.totalCampaigns}',
                  ),
                ],
              ),
              if (primary != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: CampaignStatusBadge(status: primary.status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${primary.objective} · ${percent.format(primary.progressPercent)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotedPostsTableHeader extends StatelessWidget {
  const _PromotedPostsTableHeader({
    required this.density,
    required this.sortField,
    required this.onSort,
  });

  final PromotedPostsTableDensity density;
  final PromotedPostsSortField sortField;
  final ValueChanged<PromotedPostsSortField> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Widget sortLabel(String label, PromotedPostsSortField field) {
      final active = sortField == field;
      return InkWell(
        onTap: () => onSort(field),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 2),
              Icon(Icons.arrow_downward_rounded, size: 12, color: scheme.primary),
            ],
          ],
        ),
      );
    }

    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 11,
        );

    return Container(
      height: density == PromotedPostsTableDensity.wide
          ? kPromotedPostsTableHeaderHeight
          : kPromotedPostsTableHeaderHeight + 4,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _PromotedPostsRowLayout(
        density: density,
        thumb: Text(
          density == PromotedPostsTableDensity.narrow ? '' : l10n.t('thumbnail'),
          style: headerStyle,
        ),
        post: Text(l10n.t('post'), style: headerStyle),
        views: sortLabel(l10n.t('promoMetricViews'), PromotedPostsSortField.views),
        likes: density != PromotedPostsTableDensity.narrow
            ? sortLabel(l10n.t('promoMetricLikes'), PromotedPostsSortField.likes)
            : const SizedBox.shrink(),
        engagement: density == PromotedPostsTableDensity.wide
            ? sortLabel(
                l10n.t('promoMetricEngagementRate'),
                PromotedPostsSortField.engagement,
              )
            : const SizedBox.shrink(),
        impressions: sortLabel(
          l10n.t('promoImpressions'),
          PromotedPostsSortField.impressions,
        ),
        spent: sortLabel(l10n.t('promoSpent'), PromotedPostsSortField.spent),
        campaigns: density == PromotedPostsTableDensity.wide
            ? sortLabel(
                l10n.t('promoCampaignCount'),
                PromotedPostsSortField.campaigns,
              )
            : const SizedBox.shrink(),
        primary: density != PromotedPostsTableDensity.narrow
            ? Text(l10n.t('promoPrimaryCampaign'), style: headerStyle)
            : const SizedBox.shrink(),
        actions: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PromotedPostsTableRow extends StatefulWidget {
  const _PromotedPostsTableRow({
    required this.row,
    required this.density,
    required this.striped,
    required this.onViewAnalytics,
    required this.onViewHistory,
  });

  final PromotedPostEntity row;
  final PromotedPostsTableDensity density;
  final bool striped;
  final VoidCallback onViewAnalytics;
  final VoidCallback onViewHistory;

  @override
  State<_PromotedPostsTableRow> createState() => _PromotedPostsTableRowState();
}

class _PromotedPostsTableRowState extends State<_PromotedPostsTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final density = widget.density;
    final row = widget.row;
    final compact = NumberFormat.compact();
    final percent = NumberFormat('#0.##');
    final primary = row.primaryCampaign;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );
    final numericStyle = cellStyle?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final thumbSize = promotedPostsThumbSize(density);
    final rowHeight = promotedPostsTableRowHeight(density);

    Color rowColor;
    if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onViewAnalytics,
          mouseCursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _PromotedPostsRowLayout(
                density: density,
                thumb: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: thumbSize,
                    height: thumbSize,
                    child: _PostThumbnail(post: row.post),
                  ),
                ),
                post: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.post.description?.trim().isNotEmpty == true
                          ? row.post.description!.trim()
                          : l10n.t('noDescription'),
                      maxLines: density == PromotedPostsTableDensity.narrow
                          ? 1
                          : 2,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.post.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                views: Text(
                  compact.format(row.statistics.views),
                  style: numericStyle,
                ),
                likes: density != PromotedPostsTableDensity.narrow
                    ? Text(
                        compact.format(row.statistics.likes),
                        style: numericStyle,
                      )
                    : const SizedBox.shrink(),
                engagement: density == PromotedPostsTableDensity.wide
                    ? Text(
                        '${percent.format(row.statistics.engagementRate)}%',
                        style: numericStyle?.copyWith(fontWeight: FontWeight.w700),
                      )
                    : const SizedBox.shrink(),
                impressions: Text(
                  compact.format(row.promotion.totalImpressions),
                  style: numericStyle,
                ),
                spent: Text(
                  CoinFormat.coins(row.promotion.totalSpentCoins),
                  style: numericStyle,
                ),
                campaigns: density == PromotedPostsTableDensity.wide
                    ? Text(
                        '${row.promotion.totalCampaigns}',
                        style: numericStyle,
                      )
                    : const SizedBox.shrink(),
                primary: density != PromotedPostsTableDensity.narrow
                    ? _PromotedPostPrimaryCell(
                        primary: primary,
                        density: density,
                        cellStyle: cellStyle,
                        percent: percent,
                        scheme: scheme,
                      )
                    : const SizedBox.shrink(),
                actions: _PromotedPostRowActions(
                  onViewAnalytics: widget.onViewAnalytics,
                  onViewHistory: widget.onViewHistory,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotedPostsRowLayout extends StatelessWidget {
  const _PromotedPostsRowLayout({
    required this.density,
    required this.thumb,
    required this.post,
    required this.views,
    required this.likes,
    required this.engagement,
    required this.impressions,
    required this.spent,
    required this.campaigns,
    required this.primary,
    required this.actions,
  });

  final PromotedPostsTableDensity density;
  final Widget thumb;
  final Widget post;
  final Widget views;
  final Widget likes;
  final Widget engagement;
  final Widget impressions;
  final Widget spent;
  final Widget campaigns;
  final Widget primary;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final isCompact = density == PromotedPostsTableDensity.compact;
    final isNarrow = density == PromotedPostsTableDensity.narrow || isCompact;
    final showLikes = !isNarrow;
    final showEngagement = density == PromotedPostsTableDensity.wide;
    final showCampaigns = density == PromotedPostsTableDensity.wide;
    final showPrimary = !isNarrow;
    final thumbWidth = isCompact ? 36.0 : (isNarrow ? 44.0 : 50.0);
    final cellHPad = isCompact ? 4.0 : (isNarrow ? 6.0 : _kCellHPad);
    final actionsWidth = isCompact ? 32.0 : 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: thumbWidth, child: thumb),
        Expanded(flex: isCompact ? 6 : 5, child: _cell(post, cellHPad)),
        Expanded(
          flex: 1,
          child: _cell(
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: views,
            ),
            cellHPad,
            alignEnd: true,
          ),
        ),
        if (showLikes)
          Expanded(
            flex: 1,
            child: _cell(
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: likes,
              ),
              cellHPad,
              alignEnd: true,
            ),
          ),
        if (showEngagement)
          Expanded(
            flex: 1,
            child: _cell(
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: engagement,
              ),
              cellHPad,
              alignEnd: true,
            ),
          ),
        Expanded(
          flex: 1,
          child: _cell(
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: impressions,
            ),
            cellHPad,
            alignEnd: true,
          ),
        ),
        Expanded(
          flex: 1,
          child: _cell(
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: spent,
            ),
            cellHPad,
            alignEnd: true,
          ),
        ),
        if (showCampaigns)
          Expanded(
            flex: 1,
            child: _cell(
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: campaigns,
              ),
              cellHPad,
              alignEnd: true,
            ),
          ),
        if (showPrimary) Expanded(flex: 2, child: _cell(primary, cellHPad)),
        SizedBox(width: actionsWidth, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child, double horizontalPadding, {bool alignEnd = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _PromotedPostRowActions extends StatelessWidget {
  const _PromotedPostRowActions({
    required this.onViewAnalytics,
    required this.onViewHistory,
  });

  final VoidCallback onViewAnalytics;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (value) {
        switch (value) {
          case 'analytics':
            onViewAnalytics();
          case 'history':
            onViewHistory();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'analytics',
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoViewAnalytics')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoViewHistory')),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.post});

  final PromotedPostSummaryEntity post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = post.previewThumbnailUrl;
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: (ctx, url, err) => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
    );
  }
}
