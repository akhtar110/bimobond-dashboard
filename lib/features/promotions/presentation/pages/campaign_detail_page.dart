import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/campaign_detail_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/campaign_action_dialogs.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_shared_widgets.dart';

class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<CampaignDetailBloc>(
      debugLabel: 'CampaignDetailPage',
      create: () => di.sl<CampaignDetailBloc>()
        ..add(LoadCampaignDetailEvent(campaignId)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(context.l10n.t('promoCampaignDetail')),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLowest,
          scrolledUnderElevation: 0,
        ),
        body: CampaignDetailBody(campaignId: campaignId),
      ),
    );
  }
}

class CampaignDetailBody extends StatelessWidget {
  const CampaignDetailBody({
    super.key,
    required this.campaignId,
    this.embedded = false,
    this.onDeleted,
  });

  final String campaignId;
  final bool embedded;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<CampaignDetailBloc, CampaignDetailState>(
      listenWhen: (p, c) {
        if (c is CampaignDetailError && c.message == 'deleted') return true;
        return c is CampaignDetailLoaded &&
            c.message != null &&
            (p is! CampaignDetailLoaded || p.message != c.message);
      },
      listener: (context, state) {
        if (state is CampaignDetailError && state.message == 'deleted') {
          if (embedded) {
            onDeleted?.call();
          } else {
            Navigator.of(context).pop(true);
          }
          return;
        }
        if (state is CampaignDetailLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: state.isError ? scheme.error : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final content = switch (state) {
          CampaignDetailLoading() => const Center(child: LoadingView()),
          CampaignDetailError(:final message) when message != 'deleted' =>
            Center(
              child: ErrorView(
                message: message,
                retryLabel: l10n.t('retry'),
                onRetry: () => context.read<CampaignDetailBloc>().add(
                      LoadCampaignDetailEvent(campaignId),
                    ),
              ),
            ),
          CampaignDetailLoaded() => _CampaignDetailLoadedContent(
              state: state,
              embedded: embedded,
            ),
          _ => const SizedBox.shrink(),
        };

        if (embedded) {
          return content;
        }
        return content;
      },
    );
  }
}

class _CampaignDetailLoadedContent extends StatelessWidget {
  const _CampaignDetailLoadedContent({
    required this.state,
    required this.embedded,
  });

  final CampaignDetailLoaded state;
  final bool embedded;

  Future<void> _updateStatus(BuildContext context, String status) async {
    if (state.isActioning) return;
    final confirmed = await confirmCampaignStatusChange(context, status: status);
    if (!confirmed || !context.mounted) return;
    context.read<CampaignDetailBloc>().add(UpdateCampaignDetailStatusEvent(status));
  }

  Future<void> _delete(BuildContext context) async {
    if (state.isActioning) return;
    final confirmed = await confirmCampaignDelete(context);
    if (!confirmed || !context.mounted) return;
    context.read<CampaignDetailBloc>().add(DeleteCampaignDetailEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final c = state.campaign;
    final stats = state.stats;
    final progress = stats.progressPercent.clamp(0, 100) / 100;
    final ownerLabel = c.user?.displayName ?? l10n.t('notAvailable');
    final packageLabel = c.package?.name ?? l10n.t('notAvailable');
    final dateFmt = DateFormat.yMMMd();
    final metrics = promotionsMetricsOf(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isActioning) const LinearProgressIndicator(),
        DashboardCard(
          padding: EdgeInsets.all(
            embedded ? metrics.cardPadding : metrics.cardPadding + 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              packageLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            CampaignStatusBadge(status: c.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DetailMetaLine(
                          icon: Icons.person_outline_rounded,
                          text: '${l10n.t('owner')}: $ownerLabel',
                        ),
                        const SizedBox(height: 4),
                        _DetailMetaLine(
                          icon: Icons.flag_outlined,
                          text: '${l10n.t('promoObjective')}: ${c.objective}',
                        ),
                        if (c.startAt != null || c.endAt != null) ...[
                          const SizedBox(height: 4),
                          _DetailMetaLine(
                            icon: Icons.date_range_outlined,
                            text: _formatDateRange(
                              l10n,
                              dateFmt,
                              c.startAt,
                              c.endAt,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (c.post?.previewThumbnailUrl != null) ...[
                    const SizedBox(width: PromotionsSpace.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        embedded ? 12 : (metrics.isMobile ? 12 : 16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: c.post!.previewThumbnailUrl!,
                        height: embedded ? 96 : (metrics.isMobile ? 72 : 88),
                        width: embedded ? 96 : (metrics.isMobile ? 72 : 88),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PromotionsSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('promoProgress'),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${stats.progressPercent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PromotionsSpace.lg),
        DashboardCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: state.isActioning
                    ? null
                    : () => _updateStatus(context, 'ACTIVE'),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: Text(l10n.t('promoActivate')),
              ),
              FilledButton.tonalIcon(
                onPressed: state.isActioning
                    ? null
                    : () => _updateStatus(context, 'PAUSED'),
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: Text(l10n.t('promoPause')),
              ),
              FilledButton.tonalIcon(
                onPressed: state.isActioning
                    ? null
                    : () => _updateStatus(context, 'REJECTED'),
                icon: const Icon(Icons.block, size: 18),
                label: Text(l10n.t('promoReject')),
              ),
              OutlinedButton.icon(
                onPressed: state.isActioning
                    ? null
                    : () => _updateStatus(context, 'CANCELLED'),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(l10n.t('cancel')),
              ),
              TextButton.icon(
                onPressed: state.isActioning ? null : () => _delete(context),
                icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                label: Text(
                  l10n.t('delete'),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PromotionsSpace.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = promotionsMetricColumns(constraints.maxWidth);
            final gridGap =
                metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: gridGap,
              crossAxisSpacing: gridGap,
              childAspectRatio: promotionsMetricAspectRatio(columns),
              children: [
                MetricCard(
                  title: l10n.t('promoImpressions'),
                  value: '${stats.impressionCount}',
                  subtitle: '/ ${stats.impressionTarget}',
                  icon: Icons.visibility_outlined,
                  accent: scheme.primary,
                ),
                MetricCard(
                  title: l10n.t('promoSpent'),
                  value: CoinFormat.coins(stats.spentCoins),
                  subtitle: l10n.t('promoBudget'),
                  icon: Icons.payments_outlined,
                  accent: scheme.tertiary,
                ),
                MetricCard(
                  title: l10n.t('promoBudget'),
                  value: CoinFormat.coins(stats.budgetCoins),
                  subtitle: l10n.t('promoSpendRemaining'),
                  icon: Icons.account_balance_wallet_outlined,
                  accent: scheme.secondary,
                ),
                MetricCard(
                  title: l10n.t('promoSpendRemaining'),
                  value: CoinFormat.coins(stats.remainingBudgetCoins),
                  icon: Icons.savings_outlined,
                  accent: scheme.primary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: PromotionsSpace.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            final overview = _DetailSectionCard(
              icon: Icons.info_outline_rounded,
              title: l10n.t('overview'),
              child: Column(
                children: [
                  _DetailInfoRow(
                    label: l10n.t('owner'),
                    value: ownerLabel,
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('promoObjective'),
                    value: c.objective,
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('promoPackage'),
                    value: packageLabel,
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('status'),
                    valueWidget: CampaignStatusBadge(status: c.status),
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  if (c.startAt != null)
                    _DetailInfoRow(
                      label: l10n.t('startDate'),
                      value: dateFmt.format(c.startAt!),
                      labelWidth: metrics.detailLabelWidth,
                    ),
                  if (c.endAt != null)
                    _DetailInfoRow(
                      label: l10n.t('endDate'),
                      value: dateFmt.format(c.endAt!),
                      labelWidth: metrics.detailLabelWidth,
                    ),
                  _DetailInfoRow(
                    label: l10n.t('createdAt'),
                    value: DateFormat.yMMMd().add_jm().format(c.createdAt),
                    isLast: true,
                    labelWidth: metrics.detailLabelWidth,
                  ),
                ],
              ),
            );
            final targeting = _DetailSectionCard(
              icon: Icons.my_location_outlined,
              title: l10n.t('promoTargeting'),
              child: Column(
                children: [
                  _DetailInfoRow(
                    label: l10n.t('promoGender'),
                    value: stats.targetGenders.join(', ').isEmpty
                        ? l10n.t('all')
                        : stats.targetGenders.join(', '),
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('promoAgeRange'),
                    value:
                        '${stats.targetAgeMin ?? '—'} – ${stats.targetAgeMax ?? '—'}',
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('promoCountries'),
                    value: stats.targetCountryCodes.join(', ').isEmpty
                        ? l10n.t('all')
                        : stats.targetCountryCodes.join(', '),
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  _DetailInfoRow(
                    label: l10n.t('promoLanguages'),
                    value: stats.targetLanguages.join(', ').isEmpty
                        ? l10n.t('all')
                        : stats.targetLanguages.join(', '),
                    isLast: stats.targetRadiusKm == null,
                    labelWidth: metrics.detailLabelWidth,
                  ),
                  if (stats.targetRadiusKm != null)
                    _DetailInfoRow(
                      label: l10n.t('promoGeoRadius'),
                      value: '${stats.targetRadiusKm} km',
                      isLast: true,
                      labelWidth: metrics.detailLabelWidth,
                    ),
                ],
              ),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: overview),
                  const SizedBox(width: PromotionsSpace.lg),
                  Expanded(child: targeting),
                ],
              );
            }
            return Column(
              children: [
                overview,
                const SizedBox(height: PromotionsSpace.lg),
                targeting,
              ],
            );
          },
        ),
        const SizedBox(height: PromotionsSpace.xl),
        DashboardCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(PromotionsSpace.xl),
                child: Text(
                  l10n.t('promoDeliveryLogs'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (state.impressions.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PromotionsSpace.xl,
                    0,
                    PromotionsSpace.xl,
                    PromotionsSpace.xl,
                  ),
                  child: Text(
                    l10n.t('noData'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PromotionsSpace.xl,
                    vertical: 12,
                  ),
                  color: scheme.surfaceContainerHigh,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          l10n.t('promoViewer'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l10n.t('promoCost'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          l10n.t('createdAt'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                ...state.impressions.map(
                  (i) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PromotionsSpace.xl,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            i.viewer?.displayName ?? 'Anonymous',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(CoinFormat.coins(i.costCoins)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            DateFormat.yMMMd().add_jm().format(i.createdAt),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (state.impressionsMeta.page < state.impressionsMeta.totalPages)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(PromotionsSpace.md),
                    child: TextButton.icon(
                      onPressed: state.isActioning
                          ? null
                          : () => context.read<CampaignDetailBloc>().add(
                                LoadCampaignImpressionsEvent(
                                  page: state.impressionsMeta.page + 1,
                                ),
                              ),
                      icon: const Icon(Icons.expand_more),
                      label: Text(l10n.t('loadMore')),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (embedded) const SizedBox(height: PromotionsSpace.xl),
      ],
    );

    if (embedded) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.pageHorizontalPadding,
          metrics.pageTopPadding,
          metrics.pageHorizontalPadding,
          metrics.pageBottomPadding,
        ),
        children: [body],
      );
    }

    return PromotionsDashboardShell(child: body);
  }
}

class _DetailMetaLine extends StatelessWidget {
  const _DetailMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

String _formatDateRange(
  AppLocalizations l10n,
  DateFormat dateFmt,
  DateTime? start,
  DateTime? end,
) {
  if (start != null && end != null) {
    return '${l10n.t('startDate')}: ${dateFmt.format(start)} · ${l10n.t('endDate')}: ${dateFmt.format(end)}';
  }
  if (start != null) {
    return '${l10n.t('startDate')}: ${dateFmt.format(start)}';
  }
  return '${l10n.t('endDate')}: ${dateFmt.format(end!)}';
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DashboardCard(
      padding: EdgeInsets.all(promotionsMetricsOf(context).cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: PromotionsSpace.md),
          child,
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isLast = false,
    this.labelWidth = 132,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isLast;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: promotionsMetricsOf(context).isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
