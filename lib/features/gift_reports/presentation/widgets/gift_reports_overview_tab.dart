import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/presentation/widgets/analytics_kpi_card.dart';
import '../../domain/entities/gift_report_entities.dart';
import '../bloc/gift_reports_bloc.dart';
import '../utils/gift_report_format.dart';

class GiftReportsOverviewTab extends StatelessWidget {
  const GiftReportsOverviewTab({super.key, required this.state});

  final GiftReportsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (state.isOverviewLoading && state.overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.overviewError != null && state.overview == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.overviewError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context
                  .read<GiftReportsBloc>()
                  .add(LoadGiftReportsOverviewEvent()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final overview = state.overview;
    if (overview == null) {
      return const Center(child: Text('No overview data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DaysChip(
                days: 7,
                selected: state.days == 7,
                onTap: () => context
                    .read<GiftReportsBloc>()
                    .add(ChangeGiftReportsDaysEvent(7)),
              ),
              _DaysChip(
                days: 30,
                selected: state.days == 30,
                onTap: () => context
                    .read<GiftReportsBloc>()
                    .add(ChangeGiftReportsDaysEvent(30)),
              ),
              _DaysChip(
                days: 90,
                selected: state.days == 90,
                onTap: () => context
                    .read<GiftReportsBloc>()
                    .add(ChangeGiftReportsDaysEvent(90)),
              ),
              if (state.isOverviewLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 700
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Catalog',
                      value: '${overview.totalGifts}',
                      subtitle: '${overview.activeGifts} active',
                      icon: Icons.card_giftcard_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Period sends',
                      value: formatReportCount(overview.periodTransactions),
                      subtitle: '${overview.transactionsInPeriod} in window',
                      icon: Icons.send_rounded,
                      accent: scheme.secondary,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Period spend',
                      value: formatReportCoins(overview.periodSpendCoins),
                      subtitle:
                          'Commission ${formatReportCoins(overview.periodCommissionCoins)}',
                      icon: Icons.payments_outlined,
                      accent: scheme.tertiary,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'All-time spend',
                      value: formatReportCoins(overview.allTimeSpendCoins),
                      subtitle:
                          'Contribution ${formatReportCoins(overview.allTimeContributionCoins)}',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AnalyticsSectionCard(
            title: 'Send context (${state.days}d)',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AnalyticsMiniStat(
                  label: 'To posts',
                  value: formatReportCount(overview.toPost),
                  icon: Icons.article_outlined,
                ),
                AnalyticsMiniStat(
                  label: 'To live',
                  value: formatReportCount(overview.toLive),
                  icon: Icons.live_tv_outlined,
                ),
                AnalyticsMiniStat(
                  label: 'To auctions',
                  value: formatReportCount(overview.toAuction),
                  icon: Icons.gavel_outlined,
                ),
                AnalyticsMiniStat(
                  label: 'Direct',
                  value: formatReportCount(overview.direct),
                  icon: Icons.touch_app_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnalyticsSectionCard(
                      title: 'Top gifts by sends',
                      child: _TopGiftsList(items: overview.topGiftsBySends),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  Expanded(
                    child: AnalyticsSectionCard(
                      title: 'Top gifts by revenue',
                      child: _TopGiftsList(items: overview.topGiftsByRevenue),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('Last $days days'),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TopGiftsList extends StatelessWidget {
  const _TopGiftsList({required this.items});

  final List<GiftReportTopGiftSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No data for this period');
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(formatReportCount(item.transactions)),
                const SizedBox(width: 12),
                Text(formatReportCoins(item.spendCoins)),
              ],
            ),
          ),
      ],
    );
  }
}
