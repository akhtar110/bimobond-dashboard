import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
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
                    const LinearProgressIndicator(),
                  ],
                  SizedBox(height: metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg),
                  _CampaignsBody(blocState: state),
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

            final search = _CampaignSearchField(
              hint: l10n.t('promoSearchCampaigns'),
              initialValue: query.search ?? '',
              height: controlHeight,
              compact: metrics.isMobile,
              onChanged: (q) => context
                  .read<CampaignsBloc>()
                  .add(SearchCampaignsEvent(q)),
            );

            final status = SizedBox(
              height: controlHeight,
              child: _CampaignFilterDropdown(
                hint: l10n.t('status'),
                value: query.status,
                compact: metrics.isMobile,
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
              ),
            );

            final objective = SizedBox(
              height: controlHeight,
              child: _CampaignFilterDropdown(
                hint: l10n.t('promoObjective'),
                value: query.objective,
                compact: metrics.isMobile,
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
              ),
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

class _CampaignSearchField extends StatefulWidget {
  const _CampaignSearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
    this.height = 40,
    this.compact = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final double height;
  final bool compact;

  @override
  State<_CampaignSearchField> createState() => _CampaignSearchFieldState();
}

class _CampaignSearchFieldState extends State<_CampaignSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_CampaignSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final fontSize = widget.compact ? 12.0 : 13.0;

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: fontSize),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: fontSize,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: widget.compact ? 16 : 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: widget.compact ? 14 : 16,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 8,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _CampaignFilterDropdown extends StatelessWidget {
  const _CampaignFilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.compact = false,
  });

  final String hint;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: compact ? 12 : null,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: compact ? 16 : 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
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

class _CampaignsBody extends StatelessWidget {
  const _CampaignsBody({required this.blocState});

  final CampaignsState blocState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return switch (blocState) {
      CampaignsInitial() || CampaignsLoading() => const _PageStateBox(
          child: LoadingView(),
        ),
      CampaignsError(:final message) => _PageStateBox(
          child: ErrorView(
            message: message,
            retryLabel: l10n.t('retry'),
            onRetry: () =>
                context.read<CampaignsBloc>().add(LoadCampaignsEvent()),
          ),
        ),
      CampaignsLoaded loaded => _CampaignsLoadedBody(state: loaded),
      _ => const _PageStateBox(child: LoadingView()),
    };
  }
}

class _PageStateBox extends StatelessWidget {
  const _PageStateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(child: child),
    );
  }
}

class _CampaignsLoadedBody extends StatelessWidget {
  const _CampaignsLoadedBody({required this.state});

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
        if (state.campaigns.isEmpty)
          _PageStateBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: PromotionsSpace.lg),
                Text(
                  l10n.t('promoNoCampaigns'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: PromotionsSpace.sm),
                Text(
                  l10n.t('promoNoCampaignsHint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        else ...[
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
        if (promotionsMetricsOf(context).useDesktopPagination)
          PromotionsPaginationBar(
            page: state.meta.page,
            totalPages: state.meta.totalPages,
            total: state.meta.total,
            metrics: promotionsMetricsOf(context),
            onPage: (p) =>
                context.read<CampaignsBloc>().add(LoadCampaignsEvent(page: p)),
          )
        else ...[
          if (state.isLoadingMore)
            const PromotionsLoadMoreFooter(isLoading: true),
          if (state.meta.hasReachedMax && state.campaigns.isNotEmpty)
            PromotionsLoadMoreFooter(
              hasReachedMax: true,
              total: state.meta.total,
            ),
        ],
        ],
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
