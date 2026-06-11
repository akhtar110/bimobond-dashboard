import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../analytics/presentation/utils/analytics_format.dart';
import '../../../analytics/presentation/widgets/analytics_kpi_card.dart';
import '../../domain/entities/auction_report_entities.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../reports/presentation/widgets/reports_embedded_panel.dart';
import '../bloc/auction_report_detail_bloc.dart';

class AuctionReportDetailPage extends StatefulWidget {
  const AuctionReportDetailPage({
    super.key,
    required this.auctionId,
    this.initialDays = 30,
    this.onClose,
  });

  final String auctionId;
  final int initialDays;
  final VoidCallback? onClose;

  @override
  State<AuctionReportDetailPage> createState() => _AuctionReportDetailPageState();
}

class _AuctionReportDetailPageState extends State<AuctionReportDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuctionReportDetailBloc>().add(
          LoadAuctionReportDetailEvent(
            auctionId: widget.auctionId,
            days: widget.initialDays,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return _AuctionReportDetailView(onClose: widget.onClose);
  }
}

class _AuctionReportDetailView extends StatelessWidget {
  const _AuctionReportDetailView({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final actions = <Widget>[
      BlocBuilder<AuctionReportDetailBloc, AuctionReportDetailState>(
        builder: (context, state) {
          final days = state is AuctionReportDetailLoaded ? state.days : 30;
          final periodL10n = context.l10n;
          return SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 7,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 7)),
              ),
              ButtonSegment(
                value: 30,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 30)),
              ),
              ButtonSegment(
                value: 90,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 90)),
              ),
            ],
            selected: {days},
            onSelectionChanged: (selection) {
              context.read<AuctionReportDetailBloc>().add(
                    ChangeAuctionReportDetailDaysEvent(selection.first),
                  );
            },
          );
        },
      ),
      IconButton(
        tooltip: l10n.t('refresh'),
        onPressed: () => context
            .read<AuctionReportDetailBloc>()
            .add(RefreshAuctionReportDetailEvent()),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ];

    return ReportsDetailShell(
      title: ReportDetailLabels.auctionReportTitle(l10n),
      subtitle: ReportDetailLabels.auctionReportSubtitle(l10n),
      onClose: onClose,
      backgroundColor: scheme.surfaceContainerLowest,
      actions: actions,
      body: BlocBuilder<AuctionReportDetailBloc, AuctionReportDetailState>(
        builder: (context, state) {
          if (state is AuctionReportDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AuctionReportDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<AuctionReportDetailBloc>()
                        .add(RefreshAuctionReportDetailEvent()),
                    child: Text(context.l10n.t('retry')),
                  ),
                ],
              ),
            );
          }
          if (state is! AuctionReportDetailLoaded) {
            return const SizedBox.shrink();
          }

          final detail = state.detail;
          return Column(
            children: [
              if (state.isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuctionHeader(auction: detail.auction),
                      const SizedBox(height: 12),
                      Text(
                        AnalyticsFormat.rangeLabel(
                          detail.period.from,
                          detail.period.to,
                        ),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      _MetricsGrid(detail: detail),
                      const SizedBox(height: 12),
                      _ProgressSection(metrics: detail.metrics),
                      const SizedBox(height: 12),
                      _PeriodActivitySection(activity: detail.periodActivity),
                      const SizedBox(height: 12),
                      _RecentSection(
                        title: ReportDetailLabels.recentBids(l10n),
                        emptyLabel: ReportDetailLabels.noRecentBids(l10n),
                        children: detail.recentBids
                            .map((b) => _BidTile(bid: b))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      _RecentSection(
                        title: ReportDetailLabels.recentGifts(l10n),
                        emptyLabel: ReportDetailLabels.noRecentGifts(l10n),
                        children: detail.recentGifts
                            .map((g) => _GiftTile(gift: g))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      _ContributorsSection(
                        contributors: detail.topContributors,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuctionHeader extends StatelessWidget {
  const _AuctionHeader({required this.auction});

  final AuctionReportListItem auction;

  static String _formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy HH:mm').format(date);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final image = resolveMediaUrl(auction.itemImageUrl);

    return AnalyticsSectionCard(
      title: auction.itemName,
      subtitle:
          '@${auction.host?.username ?? auction.hostId} · ${auction.status}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: image,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    ReportDetailLabels.targetPrice(
                      l10n,
                      AnalyticsFormat.usd(auction.targetPriceUsd),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    ReportDetailLabels.startPrice(
                      l10n,
                      AnalyticsFormat.usd(auction.startingPriceUsd),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (auction.winner != null)
                  Chip(
                    label: Text(
                      ReportDetailLabels.winnerUser(
                        l10n,
                        auction.winner!.username,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                if (auction.post != null)
                  Chip(
                    label: Text(ReportDetailLabels.postLinked(l10n)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (auction.live != null)
                  Chip(
                    label: Text(ReportDetailLabels.liveLinked(l10n)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(auction.startedAt),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.detail});

  final AuctionReportDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = detail.metrics;
    final c = detail.counts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            AnalyticsKpiCard(
              title: ReportDetailLabels.raised(l10n),
              value: AnalyticsFormat.usd(m.currentTotalUsd),
              subtitle: ReportDetailLabels.remaining(
                l10n,
                AnalyticsFormat.usd(m.remainingUsd),
              ),
              icon: Icons.payments_outlined,
            ),
            AnalyticsKpiCard(
              title: ReportDetailLabels.target(l10n),
              value: AnalyticsFormat.usd(m.targetPriceUsd),
              subtitle: ReportDetailLabels.percentComplete(
                l10n,
                m.progressPercent,
              ),
              icon: Icons.flag_outlined,
            ),
            AnalyticsKpiCard(
              title: ReportDetailLabels.bids(l10n),
              value: AnalyticsFormat.count(c.bids),
              subtitle: ReportDetailLabels.allTimeManualBids(l10n),
              icon: Icons.gavel_rounded,
            ),
            AnalyticsKpiCard(
              title: l10n.t('gifts'),
              value: AnalyticsFormat.count(c.giftTransactions),
              subtitle: ReportDetailLabels.giftTransactions(l10n),
              icon: Icons.card_giftcard_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.metrics});

  final AuctionReportMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final progress = (metrics.progressPercent / 100).clamp(0.0, 1.0);

    return AnalyticsSectionCard(
      title: ReportDetailLabels.auctionProgress(l10n),
      subtitle: ReportDetailLabels.ofAmount(
        l10n,
        AnalyticsFormat.usd(metrics.currentTotalUsd),
        AnalyticsFormat.usd(metrics.targetPriceUsd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ReportDetailLabels.percentToTarget(
              l10n,
              metrics.progressPercent,
              AnalyticsFormat.usd(metrics.remainingUsd),
            ),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PeriodActivitySection extends StatelessWidget {
  const _PeriodActivitySection({required this.activity});

  final AuctionReportPeriodActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnalyticsSectionCard(
      title: ReportDetailLabels.periodActivity(l10n),
      subtitle: ReportDetailLabels.bidsAndGiftsInRange(l10n),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          AnalyticsMiniStat(
            label: ReportDetailLabels.bids(l10n),
            value: AnalyticsFormat.count(activity.bids),
            icon: Icons.gavel_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('gifts'),
            value: AnalyticsFormat.count(activity.gifts),
            icon: Icons.card_giftcard_outlined,
          ),
          AnalyticsMiniStat(
            label: ReportDetailLabels.contribution(l10n),
            value: AnalyticsFormat.usd(activity.contributionUsd),
            icon: Icons.savings_outlined,
          ),
          AnalyticsMiniStat(
            label: ReportDetailLabels.giftSpend(l10n),
            value: AnalyticsFormat.usd(activity.giftSpendUsd),
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.title,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: title,
      child: children.isEmpty
          ? Text(
              emptyLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(children: children),
    );
  }
}

class _BidTile extends StatelessWidget {
  const _BidTile({required this.bid});

  final AuctionReportBid bid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _UserAvatar(user: bid.bidder),
      title: Text(AnalyticsFormat.usd(bid.amountUsd)),
      subtitle: Text(
        '@${bid.bidder?.username ?? ReportDetailLabels.unknown(l10n)} · '
        '${DateFormat('MMM d, yyyy HH:mm').format(bid.createdAt)}',
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift});

  final AuctionReportGiftTransaction gift;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thumb = resolveMediaUrl(gift.gift?.thumbnailUrl);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: thumb != null
          ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(thumb))
          : const CircleAvatar(child: Icon(Icons.card_giftcard_outlined)),
      title: Text(gift.gift?.name ?? ReportDetailLabels.giftLabel(l10n)),
      subtitle: Text(
        '@${gift.sender?.username ?? ReportDetailLabels.unknown(l10n)} · '
        '${AnalyticsFormat.usd(gift.priceUsd)} '
        '(+${AnalyticsFormat.usd(gift.contributionUsd)})',
      ),
      trailing: Text(DateFormat('MMM d').format(gift.createdAt)),
    );
  }
}

class _ContributorsSection extends StatelessWidget {
  const _ContributorsSection({required this.contributors});

  final List<AuctionReportContributor> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnalyticsSectionCard(
      title: ReportDetailLabels.topContributors(l10n),
      subtitle: ReportDetailLabels.topContributorsSubtitle(l10n),
      child: contributors.isEmpty
          ? Text(
              ReportDetailLabels.noContributorsYet(l10n),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: contributors
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _UserAvatar(user: c.user),
                      title: Text(c.user.displayName),
                      subtitle: Text(
                        '@${c.user.username} · '
                        '${ReportDetailLabels.giftsCount(l10n, c.giftCount)}',
                      ),
                      trailing: Text(
                        AnalyticsFormat.usd(c.totalContributionUsd),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final ReportAdminUser? user;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(user?.avatarUrl);
    return CircleAvatar(
      backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
      child: url == null ? const Icon(Icons.person_outline_rounded) : null,
    );
  }
}
