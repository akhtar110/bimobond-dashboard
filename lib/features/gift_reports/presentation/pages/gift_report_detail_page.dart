import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_report_entities.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../reports/presentation/widgets/report_detail_header_layout.dart';
import '../../../reports/presentation/widgets/report_detail_metric_card.dart';
import '../../../reports/presentation/widgets/reports_embedded_panel.dart';
import '../bloc/gift_report_detail_bloc.dart';
import '../utils/gift_report_format.dart';

class GiftReportDetailPage extends StatelessWidget {
  const GiftReportDetailPage({
    super.key,
    required this.giftId,
    this.onClose,
  });

  final String giftId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('GiftReportDetailPage rebuilt');
    return PersistentBlocProvider<GiftReportDetailBloc>(
      debugLabel: 'GiftReportDetailPage',
      create: () => di.sl<GiftReportDetailBloc>()
        ..add(LoadGiftReportDetailEvent(giftId: giftId)),
      child: _GiftReportDetailView(giftId: giftId, onClose: onClose),
    );
  }
}

class _GiftReportDetailView extends StatelessWidget {
  const _GiftReportDetailView({required this.giftId, this.onClose});

  final String giftId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final actions = <Widget>[
      BlocBuilder<GiftReportDetailBloc, GiftReportDetailState>(
        builder: (context, state) {
          final days = state is GiftReportDetailLoaded ? state.days : 30;
          return PopupMenuButton<int>(
            tooltip: ReportDetailLabels.period(l10n),
            icon: const Icon(Icons.date_range_outlined),
            onSelected: (value) => context
                .read<GiftReportDetailBloc>()
                .add(ChangeGiftReportDetailDaysEvent(value)),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 7,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 7, selected: days == 7),
                ),
              ),
              PopupMenuItem(
                value: 30,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 30, selected: days == 30),
                ),
              ),
              PopupMenuItem(
                value: 90,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 90, selected: days == 90),
                ),
              ),
            ],
          );
        },
      ),
      IconButton(
        tooltip: l10n.t('refresh'),
        onPressed: () => context
            .read<GiftReportDetailBloc>()
            .add(RefreshGiftReportDetailEvent()),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ];

    return ReportsDetailShell(
      title: ReportDetailLabels.giftReportTitle(l10n),
      subtitle: ReportDetailLabels.giftReportSubtitle(l10n),
      onClose: onClose,
      backgroundColor: scheme.surfaceContainerLowest,
      actions: actions,
      body: BlocBuilder<GiftReportDetailBloc, GiftReportDetailState>(
        builder: (context, state) {
          if (state is GiftReportDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GiftReportDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<GiftReportDetailBloc>()
                        .add(RefreshGiftReportDetailEvent()),
                    child: Text(l10n.t('retry')),
                  ),
                ],
              ),
            );
          }
          if (state is GiftReportDetailLoaded) {
            return _DetailBody(detail: state.detail, days: state.days);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.days});

  final GiftReportDetailEntity detail;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gift = detail.gift;
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportDetailHeaderSplit(
                start: ReportDetailHeaderCard(
                  title: gift.name,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: gift.thumbnailUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: gift.thumbnailUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                color: scheme.primaryContainer,
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: scheme.primary,
                                  size: 32,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                end: ReportDetailHeaderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatReportCoins(gift.priceCoins),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        gift.isActive ? l10n.t('active') : l10n.t('inactive'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ReportDetailMetricsGrid(
                children: [
                  ReportDetailMetricCard(
                    title: ReportDetailLabels.allTimeSpend(l10n),
                    value: formatReportCoins(detail.allTimeSpendCoins),
                    icon: Icons.savings_outlined,
                    accent: const Color(0xFFD97706),
                  ),
                  ReportDetailMetricCard(
                    title: ReportDetailLabels.periodSends(l10n, days),
                    value: formatReportCount(detail.periodTransactions),
                    icon: Icons.outbound_rounded,
                    accent: const Color(0xFF2563EB),
                  ),
                  ReportDetailMetricCard(
                    title: ReportDetailLabels.periodSpend(l10n),
                    value: formatReportCoins(detail.periodSpendCoins),
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFF059669),
                  ),
                  ReportDetailMetricCard(
                    title: ReportDetailLabels.inventoryQty(l10n),
                    value: formatReportCount(detail.counts.inventoryQuantity),
                    icon: Icons.inventory_2_outlined,
                    accent: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: ReportDetailLabels.contextBreakdown(l10n),
                child: ReportDetailMetricsGrid(
                  children: [
                    ReportDetailCountMetricCard(
                      title: l10n.t('posts'),
                      count: detail.toPost,
                      icon: Icons.article_outlined,
                      accent: const Color(0xFF2563EB),
                    ),
                    ReportDetailCountMetricCard(
                      title: ReportDetailLabels.live(l10n),
                      count: detail.toLive,
                      icon: Icons.live_tv_outlined,
                      accent: const Color(0xFFDB2777),
                    ),
                    ReportDetailCountMetricCard(
                      title: l10n.t('auctions'),
                      count: detail.toAuction,
                      icon: Icons.gavel_rounded,
                      accent: const Color(0xFFD97706),
                    ),
                    ReportDetailCountMetricCard(
                      title: ReportDetailLabels.direct(l10n),
                      count: detail.direct,
                      icon: Icons.send_outlined,
                      accent: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 560;
                  final senders = _Section(
                    title: ReportDetailLabels.topSenders(l10n),
                    child: _TopSendersList(items: detail.topSenders),
                  );
                  final receivers = _Section(
                    title: ReportDetailLabels.topReceivers(l10n),
                    child: _TopReceiversList(items: detail.topReceivers),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: senders),
                        const SizedBox(width: 16),
                        Expanded(child: receivers),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      senders,
                      const SizedBox(height: 16),
                      receivers,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _Section(
                title: ReportDetailLabels.giftTransactions(l10n),
                child: detail.recentTransactions.isEmpty
                    ? Text(ReportDetailLabels.noRecentTransactions(l10n))
                    : Column(
                        children: [
                          for (final tx in detail.recentTransactions)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${tx.sender?.displayName ?? tx.senderId} → '
                                '${tx.receiver?.displayName ?? tx.receiverId}',
                              ),
                              subtitle: Text(formatReportDate(tx.createdAt)),
                              trailing: Text(formatReportCoins(tx.priceCoins)),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TopSendersList extends StatelessWidget {
  const _TopSendersList({required this.items});

  final List<GiftReportTopUserActivity> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (items.isEmpty) {
      return Text(ReportDetailLabels.noSendersYet(l10n));
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.user.displayName),
            subtitle: Text(ReportDetailLabels.sendsCount(l10n, item.sendCount)),
            trailing: Text(formatReportCoins(item.spendCoins)),
          ),
      ],
    );
  }
}

class _TopReceiversList extends StatelessWidget {
  const _TopReceiversList({required this.items});

  final List<GiftReportTopReceiverActivity> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (items.isEmpty) {
      return Text(ReportDetailLabels.noReceiversYet(l10n));
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.user.displayName),
            subtitle: Text(
              ReportDetailLabels.receivesCount(l10n, item.receiveCount),
            ),
            trailing: Text(formatReportCoins(item.earnedCoins)),
          ),
      ],
    );
  }
}
