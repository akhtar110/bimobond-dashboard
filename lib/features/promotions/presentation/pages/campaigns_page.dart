import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_dropdown.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/campaigns_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/campaigns_table.dart';
import '../widgets/campaign_detail_sheet.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_data_display_widgets.dart';
import '../widgets/promotions_pagination_bar.dart';
import '../widgets/promotions_shared_widgets.dart';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (!promotionsMetricsOf(context).useInfiniteScroll) return;
    if (!promotionsShouldLoadMore(_scrollController)) return;
    context.read<CampaignsBloc>().add(LoadMoreCampaignsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CampaignsBloc, CampaignsState>(
      listenWhen: (p, c) =>
          c is CampaignsLoaded &&
          c.message != null &&
          (p is! CampaignsLoaded || p.message != c.message),
      listener: (context, state) {
        if (state is! CampaignsLoaded || state.message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor: state.isError
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        );
      },
      builder: (context, state) {
        final isInitialLoad =
            state is CampaignsInitial || state is CampaignsLoading;
        final isRefreshing =
            state is CampaignsLoaded && state.isActioning && !state.isLoadingMore;
        final showProgress = isInitialLoad || isRefreshing;

        return PromotionsDashboardShell(
          scrollController: _scrollController,
          child: Builder(
            builder: (context) {
              final metrics = promotionsMetricsOf(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.t('promoCampaignsTitle'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: metrics.isMobile ? 20 : null,
                        ),
                  ),
                  SizedBox(height: metrics.sectionGap),
                  const _CampaignsFilters(),
                  if (showProgress) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(height: metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg),
                  _CampaignsDataSection(blocState: state),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CampaignsFilters extends StatelessWidget {
  const _CampaignsFilters();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<CampaignsBloc, CampaignsState, AdminCampaignsQuery>(
      selector: _campaignQueryFrom,
      builder: (context, query) {
        final hasActiveFilters = _campaignsHasActiveFilters(query);

        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = PromotionsLayoutMetrics(
              getPromotionsDeviceType(constraints.maxWidth),
            );
            final narrow = constraints.maxWidth < 760;
            final controlHeight = metrics.filterControlHeight;
            final gap = metrics.toolbarFilterGap;

            final search = PromotionsToolbarSearchField(
              hint: l10n.t('promoSearchCampaigns'),
              initialValue: query.search ?? '',
              height: controlHeight,
              compact: metrics.isMobile,
              onChanged: (q) => context
                  .read<CampaignsBloc>()
                  .add(SearchCampaignsEvent(q)),
            );

            final status = ToolbarFilterDropdown<String?>(
              hint: l10n.t('status'),
              value: query.status,
              height: controlHeight,
              items: [null, ...CampaignStatus.values.map((s) => s.apiValue)],
              itemLabel: (v) {
                if (v == null) return l10n.t('all');
                return switch (CampaignStatus.tryParse(v)) {
                  CampaignStatus.pendingPayment =>
                    l10n.t('promoStatusPendingPayment'),
                  CampaignStatus.active => l10n.t('promoStatusActive'),
                  CampaignStatus.paused => l10n.t('promoStatusPaused'),
                  CampaignStatus.completed => l10n.t('promoStatusCompleted'),
                  CampaignStatus.cancelled => l10n.t('promoStatusCancelled'),
                  CampaignStatus.rejected => l10n.t('promoStatusRejected'),
                  _ => v,
                };
              },
              onChanged: (v) => context
                  .read<CampaignsBloc>()
                  .add(FilterCampaignStatusEvent(v)),
            );

            final objective = ToolbarFilterDropdown<String?>(
              hint: l10n.t('promoObjective'),
              value: query.objective,
              height: controlHeight,
              items: [
                null,
                ...CampaignObjective.values.map((o) => o.apiValue),
              ],
              itemLabel: (v) {
                if (v == null) return l10n.t('all');
                return switch (CampaignObjective.tryParse(v)) {
                  CampaignObjective.views => 'Views',
                  CampaignObjective.followers => 'Followers',
                  CampaignObjective.engagement => 'Engagement',
                  CampaignObjective.challenges => 'Challenges',
                  CampaignObjective.profileVisits => 'Profile visits',
                  CampaignObjective.sales => 'Sales',
                  _ => v,
                };
              },
              onChanged: (v) => context
                  .read<CampaignsBloc>()
                  .add(FilterCampaignObjectiveEvent(v)),
            );

            final clearButton = hasActiveFilters
                ? IconButton(
                    tooltip: l10n.t('clearFilters'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context
                        .read<CampaignsBloc>()
                        .add(ClearCampaignFiltersEvent()),
                    icon: Icon(
                      Icons.filter_alt_off_outlined,
                      size: 18,
                      color: scheme.error,
                    ),
                  )
                : null;

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  SizedBox(height: metrics.filterGap),
                  Row(
                    children: [
                      Expanded(child: status),
                      SizedBox(width: gap),
                      Expanded(child: objective),
                      if (clearButton != null) clearButton,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: search),
                SizedBox(width: metrics.filterGap),
                SizedBox(
                  width: metrics.isMobile ? 132 : 148,
                  child: status,
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: metrics.isMobile ? 132 : 148,
                  child: objective,
                ),
                if (clearButton != null) clearButton,
              ],
            );
          },
        );
      },
    );
  }
}

class _CampaignsDataSection extends StatelessWidget {
  const _CampaignsDataSection({required this.blocState});

  final CampaignsState blocState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = blocState is CampaignsInitial || blocState is CampaignsLoading;
    final errorMessage = switch (blocState) {
      CampaignsError(:final message) => message,
      _ => null,
    };
    final loaded = blocState is CampaignsLoaded ? blocState as CampaignsLoaded : null;
    final isEmpty = loaded != null && loaded.campaigns.isEmpty;

    Widget? footer;
    if (loaded != null) {
      if (promotionsMetricsOf(context).useDesktopPagination) {
        footer = PromotionsPaginationBar(
          page: loaded.meta.page,
          totalPages: loaded.meta.totalPages,
          total: loaded.meta.total,
          pageSize: loaded.meta.limit,
          itemCount: loaded.campaigns.length,
          metrics: promotionsMetricsOf(context),
          showTopBorder: true,
          onPage: (p) =>
              context.read<CampaignsBloc>().add(LoadCampaignsEvent(page: p)),
        );
      } else if (loaded.isLoadingMore) {
        footer = const PromotionsLoadMoreIndicator();
      } else if (loaded.meta.hasReachedMax && loaded.campaigns.isNotEmpty) {
        footer = const PromotionsEndOfListLabel();
      }
    }

    return PromotionsDataSection(
      footer: footer,
      child: PromotionsDataBody(
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: () => context.read<CampaignsBloc>().add(LoadCampaignsEvent()),
        isEmpty: isEmpty,
        emptyMessage: l10n.t('noData'),
        child: loaded == null
            ? const SizedBox.shrink()
            : _CampaignsLoadedContent(state: loaded),
      ),
    );
  }
}

class _CampaignsLoadedContent extends StatelessWidget {
  const _CampaignsLoadedContent({required this.state});

  final CampaignsLoaded state;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat.yMMMd();
    final l10n = context.l10n;
    final canWrite = context.select<AuthBloc, bool>((b) {
      final auth = b.state;
      if (auth is Authenticated) return canWritePromotions(auth.user.roles);
      return false;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canWrite)
          BulkActionToolbar(
            selectedCount: state.selectedIds.length,
            allVisibleSelected: state.allVisibleSelected,
            someVisibleSelected: state.someVisibleSelected,
            onSelectAll: () =>
                context.read<CampaignsBloc>().add(SelectAllCampaignsEvent()),
            onClear: () =>
                context.read<CampaignsBloc>().add(ClearCampaignSelectionEvent()),
            actions: [
              FilledButton.tonal(
                onPressed: state.selectedIds.isEmpty || state.isActioning
                    ? null
                    : () => _bulk(context, BulkCampaignAction.pause),
                child: Text(l10n.t('promoBulkPause')),
              ),
              FilledButton.tonal(
                onPressed: state.selectedIds.isEmpty || state.isActioning
                    ? null
                    : () => _bulk(context, BulkCampaignAction.activate),
                child: Text(l10n.t('promoBulkActivate')),
              ),
              FilledButton.tonal(
                onPressed: state.selectedIds.isEmpty || state.isActioning
                    ? null
                    : () => _bulk(context, BulkCampaignAction.reject),
                child: Text(l10n.t('promoBulkReject')),
              ),
              FilledButton(
                onPressed: state.selectedIds.isEmpty || state.isActioning
                    ? null
                    : () => _bulk(context, BulkCampaignAction.delete),
                child: Text(l10n.t('delete')),
              ),
            ],
          ),
        if (canWrite && state.selectedIds.isNotEmpty)
          const SizedBox(height: PromotionsSpace.md),
        CampaignsTable(
          campaigns: state.campaigns,
          selectedIds: state.selectedIds,
          allVisibleSelected: state.allVisibleSelected,
          someVisibleSelected: state.someVisibleSelected,
          currency: currency,
          dateFmt: dateFmt,
          showProgress: state.isActioning && !state.isLoadingMore,
          readOnly: !canWrite,
          onSelectAll: () =>
              context.read<CampaignsBloc>().add(SelectAllCampaignsEvent()),
          onToggle: (id) => context
              .read<CampaignsBloc>()
              .add(ToggleCampaignSelectionEvent(id)),
          onOpen: (campaign) async {
            final changed =
                await showCampaignDetailSheet(context, campaign.id);
            if (!context.mounted || changed != true) return;
            context.read<CampaignsBloc>().add(LoadCampaignsEvent(refresh: true));
          },
          onStatus: (id, status) => context.read<CampaignsBloc>().add(
                UpdateCampaignStatusFromListEvent(id, status),
              ),
          onDelete: (id) =>
              context.read<CampaignsBloc>().add(DeleteCampaignFromListEvent(id)),
        ),
      ],
    );
  }

  void _bulk(BuildContext context, BulkCampaignAction action) {
    final bloc = context.read<CampaignsBloc>();
    final bulkBloc = context.read<BulkActionsBloc>();
    final current = bloc.state;
    if (current is! CampaignsLoaded) return;
    bulkBloc.add(
      ExecuteBulkCampaignActionEvent(
        campaignIds: current.selectedIds.toList(),
        action: action,
      ),
    );
    bulkBloc.stream
        .firstWhere((s) => s is BulkActionsSuccess || s is BulkActionsError)
        .then((s) {
      if (!context.mounted) return;
      if (s is BulkActionsSuccess) {
        bloc.add(LoadCampaignsEvent(refresh: true));
        bloc.add(ClearCampaignSelectionEvent());
      }
    });
  }
}

AdminCampaignsQuery _campaignQueryFrom(CampaignsState state) {
  return switch (state) {
    CampaignsLoaded(:final query) => query,
    CampaignsLoading(:final query) => query,
    CampaignsError(:final query) => query,
    _ => const AdminCampaignsQuery(),
  };
}

bool _campaignsHasActiveFilters(AdminCampaignsQuery query) {
  return (query.search != null && query.search!.isNotEmpty) ||
      (query.status != null && query.status!.isNotEmpty) ||
      (query.objective != null && query.objective!.isNotEmpty);
}
