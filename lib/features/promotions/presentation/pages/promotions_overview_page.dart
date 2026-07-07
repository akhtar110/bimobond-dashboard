import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../widgets/campaign_detail_sheet.dart';
import '../../domain/entities/promotion_entities.dart';
import '../bloc/promotions_overview_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_data_display_widgets.dart';
import '../widgets/promotions_shared_widgets.dart';

class PromotionsOverviewPage extends StatelessWidget {
  const PromotionsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionsOverviewBloc, PromotionsOverviewState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final isLoading = state is PromotionsOverviewLoading;
        final isInitial = state is PromotionsOverviewInitial;
        final errorMessage = switch (state) {
          PromotionsOverviewError(:final message) => message,
          _ => null,
        };
        if (state is! PromotionsOverviewLoaded && !isLoading && !isInitial && errorMessage == null) {
          return const SizedBox.shrink();
        }

        final number = NumberFormat.compact();
        final overview = state is PromotionsOverviewLoaded ? state.overview : null;
        final recentCampaigns =
            state is PromotionsOverviewLoaded ? state.recentCampaigns : const <CampaignEntity>[];
        final moderationQueue =
            state is PromotionsOverviewLoaded ? state.moderationQueue : const <CampaignEntity>[];

        return PromotionsDashboardShell(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;
              final metrics = PromotionsLayoutMetrics(
                getPromotionsDeviceType(contentWidth),
              );
              final chartTwoCol = contentWidth >= 1000;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.t('promoOverviewTitle'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: metrics.isMobile ? 20 : null,
                        ),
                  ),
                  if (isLoading || isInitial) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (errorMessage != null) ...[
                    SizedBox(height: metrics.sectionGap),
                    PromotionsDataSection(
                      child: PromotionsDataBody(
                        errorMessage: errorMessage,
                        onRetry: () => context
                            .read<PromotionsOverviewBloc>()
                            .add(LoadPromotionsOverviewEvent()),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ] else if (overview != null) ...[
                  SizedBox(height: metrics.sectionGap),
                  _CompactOverviewMetrics(
                    items: [
                      (
                        l10n.t('promoMetricTotalCampaigns'),
                        number.format(overview.totalCampaigns),
                        Icons.campaign_outlined,
                      ),
                      (
                        l10n.t('promoMetricActiveCampaigns'),
                        number.format(overview.activeCampaigns),
                        Icons.play_circle_outline,
                      ),
                      (
                        l10n.t('promoMetricPendingPayment'),
                        number.format(overview.pendingPaymentCampaigns),
                        Icons.pending_outlined,
                      ),
                      (
                        l10n.t('promoMetricRejected'),
                        number.format(overview.rejectedCampaigns),
                        Icons.block_outlined,
                      ),
                      (
                        l10n.t('promoMetricImpressions24h'),
                        number.format(overview.impressionsLast24Hours),
                        Icons.visibility_outlined,
                      ),
                      (
                        l10n.t('promoMetricTotalRevenue'),
                        CoinFormat.coins(overview.totalSpentCoins),
                        Icons.payments_outlined,
                      ),
                      (
                        l10n.t('promoMetricSpendRemaining'),
                        CoinFormat.coins(overview.activeSpendRemainingCoins),
                        Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.sectionGap),
                  if (chartTwoCol)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AnalyticsChartCard(
                            title: l10n.t('promoRevenueTrend'),
                            child: RevenueTrendChart(overview: overview),
                          ),
                        ),
                        const SizedBox(width: PromotionsSpace.sm),
                        Expanded(
                          child: AnalyticsChartCard(
                            title: l10n.t('promoCampaignStatusChart'),
                            subtitle: l10n.t('promoMetricTotalCampaigns'),
                            icon: Icons.donut_large_outlined,
                            chartHeight: null,
                            expandChild: true,
                            child: CampaignStatusChart(overview: overview),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AnalyticsChartCard(
                      title: l10n.t('promoRevenueTrend'),
                      child: RevenueTrendChart(overview: overview),
                    ),
                    const SizedBox(height: PromotionsSpace.sm),
                    AnalyticsChartCard(
                      title: l10n.t('promoCampaignStatusChart'),
                      subtitle: l10n.t('promoMetricTotalCampaigns'),
                      icon: Icons.donut_large_outlined,
                      chartHeight: null,
                      expandChild: true,
                      child: CampaignStatusChart(overview: overview),
                    ),
                  ],
                  const SizedBox(height: PromotionsSpace.sm),
                  AnalyticsChartCard(
                    title: l10n.t('promoImpressionGrowth'),
                    subtitle:
                        '${l10n.t('promoMetricImpressions24h')} · ${l10n.t('promoImpressions')}',
                    icon: Icons.show_chart_rounded,
                    chartHeight: null,
                    expandChild: true,
                    child: ImpressionGrowthChart(overview: overview),
                  ),
                  const SizedBox(height: PromotionsSpace.lg),
                  _CampaignListSection(
                    title: l10n.t('promoRecentCampaigns'),
                    campaigns: recentCampaigns,
                  ),
                  const SizedBox(height: PromotionsSpace.sm),
                  _CampaignListSection(
                    title: l10n.t('promoModerationQueue'),
                    campaigns: moderationQueue,
                  ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CompactOverviewMetrics extends StatelessWidget {
  const _CompactOverviewMetrics({required this.items});

  final List<(String, String, IconData)> items;

  static double _stripHeight(bool isMobile) => isMobile ? 38.0 : 44.0;
  static double _defaultMaxTileWidth(bool isMobile) => isMobile ? 120.0 : 136.0;
  static double _wideMaxTileWidth(bool isMobile) => isMobile ? 132.0 : 152.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = PromotionsLayoutMetrics(
          getPromotionsDeviceType(constraints.maxWidth),
        );
        final useWrap = constraints.maxWidth < 520;
        final gap = metrics.toolbarFilterGap;

        if (useWrap) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < items.length; i++)
                _CompactMetricTile(
                  label: items[i].$1,
                  value: items[i].$2,
                  icon: items[i].$3,
                  maxWidth: _maxWidthForIndex(i, metrics.isMobile),
                  compact: metrics.isMobile,
                ),
            ],
          );
        }

        return SizedBox(
          height: _stripHeight(metrics.isMobile),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _CompactMetricTile(
                    label: items[i].$1,
                    value: items[i].$2,
                    icon: items[i].$3,
                    maxWidth: _maxWidthForIndex(i, metrics.isMobile),
                    compact: metrics.isMobile,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double _maxWidthForIndex(int index, bool isMobile) {
    // Revenue/spend tiles tend to need slightly more room.
    return index >= 5
        ? _wideMaxTileWidth(isMobile)
        : _defaultMaxTileWidth(isMobile);
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.maxWidth,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final double maxWidth;
  final bool compact;

  static const _minTileWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stripHeight = _CompactOverviewMetrics._stripHeight(compact);

    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: compact ? 76 : _minTileWidth,
          maxWidth: maxWidth,
        ),
        child: Container(
          height: stripHeight,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 12 : 14, color: scheme.primary),
              SizedBox(width: compact ? 4 : 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignListSection extends StatelessWidget {
  const _CampaignListSection({
    required this.title,
    required this.campaigns,
  });

  final String title;
  final List<CampaignEntity> campaigns;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PromotionsDataSection(
      title: title,
      child: campaigns.isEmpty
          ? Center(
              child: Text(
                l10n.t('noData'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : DecoratedBox(
              decoration: promotionsInnerTableDecoration(scheme),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < campaigns.length; i++) ...[
                      _CampaignRow(campaign: campaigns[i]),
                      if (i < campaigns.length - 1)
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
  }
}

class _CampaignRow extends StatefulWidget {
  const _CampaignRow({required this.campaign});

  final CampaignEntity campaign;

  @override
  State<_CampaignRow> createState() => _CampaignRowState();
}

class _CampaignRowState extends State<_CampaignRow> {
  bool _hovered = false;

  void _setHovered(bool hovered) {
    if (_hovered == hovered || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == hovered) return;
      setState(() => _hovered = hovered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final c = widget.campaign;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surface,
        child: InkWell(
          onTap: () => showCampaignDetailSheet(context, c.id),
          child: SizedBox(
            height: kPromotionsDataRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.user?.displayName ?? l10n.t('notAvailable'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${c.objective} · ${c.package?.name ?? l10n.t('notAvailable')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PromotionsSpace.sm),
                CampaignStatusBadge(status: c.status),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: _hovered ? 0.85 : 0.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
