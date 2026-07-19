import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_dropdown.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/promoted_posts_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/promoted_post_analytics_sheet.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_data_display_widgets.dart';
import '../widgets/promotions_pagination_bar.dart';
import '../widgets/promoted_post_widgets.dart';

class PromotedPostsPage extends StatefulWidget {
  const PromotedPostsPage({super.key});

  @override
  State<PromotedPostsPage> createState() => _PromotedPostsPageState();
}

class _PromotedPostsPageState extends State<PromotedPostsPage> {
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
    context.read<PromotedPostsBloc>().add(const LoadMorePromotedPostsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PromotedPostsBloc, PromotedPostsState>(
      listenWhen: (p, c) =>
          c is PromotedPostsLoaded &&
          c.message != null &&
          (p is! PromotedPostsLoaded || p.message != c.message),
      listener: (context, state) {
        if (state is! PromotedPostsLoaded || state.message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor:
                state.isError ? Theme.of(context).colorScheme.error : null,
          ),
        );
      },
      builder: (context, state) {
        final isInitialLoad =
            state is PromotedPostsInitial || state is PromotedPostsLoading;
        final isRefreshing = state is PromotedPostsLoaded &&
            state.isRefreshing &&
            !state.isLoadingMore;
        final isEmptyLoading =
            state is PromotedPostsEmpty && state.isLoading;
        final showProgress =
            isInitialLoad || isRefreshing || isEmptyLoading;
        final loaded =
            state is PromotedPostsLoaded ? state : null;

        return PromotionsDashboardShell(
          scrollController: _scrollController,
          child: Builder(
            builder: (context) {
              final metrics = promotionsMetricsOf(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PromotedPostsHeader(
                    metrics: metrics,
                    isBusy: showProgress,
                    onRefresh: () => context
                        .read<PromotedPostsBloc>()
                        .add(const LoadPromotedPostsEvent()),
                  ),
                  SizedBox(height: metrics.sectionGap),
                  if (loaded != null) ...[
                    _PromotedPostsSummaryStrip(state: loaded),
                    SizedBox(height: metrics.sectionGap),
                  ],
                  _PromotedPostsFilters(metrics: metrics),
                  if (showProgress) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(height: metrics.sectionGap),
                  _PromotedPostsDataSection(
                    state: state,
                    onOpenAnalytics: (postId) =>
                        _openAnalytics(context, postId),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openAnalytics(BuildContext context, String postId) {
    showPromotedPostAnalyticsSheet(context, postId);
  }
}

class _PromotedPostsHeader extends StatelessWidget {
  const _PromotedPostsHeader({
    required this.metrics,
    required this.isBusy,
    required this.onRefresh,
  });

  final PromotionsLayoutMetrics metrics;
  final bool isBusy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isMobile;

    final title = Text(
      l10n.t('promoPromotedPostsTitle'),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: compact ? 20 : null,
            height: 1.15,
          ),
    );

    final subtitle = Text(
      l10n.tOr(
        'promoPromotedPostsSubtitle',
        'Browse and analyze posts currently running promotion campaigns.',
      ),
      maxLines: compact ? 2 : 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: compact ? 12 : null,
            height: 1.35,
          ),
    );

    final refresh = IconButton(
      tooltip: l10n.t('refresh'),
      visualDensity: VisualDensity.compact,
      onPressed: isBusy ? null : onRefresh,
      icon: Icon(
        Icons.refresh_rounded,
        size: compact ? 20 : 22,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  refresh,
                ],
              ),
              SizedBox(height: metrics.toolbarFilterGap),
              subtitle,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(height: metrics.toolbarFilterGap),
                  subtitle,
                ],
              ),
            ),
            refresh,
          ],
        );
      },
    );
  }
}

class _PromotedPostsSummaryStrip extends StatelessWidget {
  const _PromotedPostsSummaryStrip({required this.state});

  final PromotedPostsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = promotionsMetricsOf(context);
    final number = NumberFormat.compact();
    final activeFilters = _promotedPostsHasActiveFilters(state.query);

    return Wrap(
      spacing: metrics.toolbarFilterGap,
      runSpacing: metrics.toolbarFilterGap,
      children: [
        _SummaryChip(
          icon: Icons.campaign_outlined,
          label: l10n.tOr('promoPromotedPostsTotal', 'Total posts'),
          value: number.format(state.meta.total),
        ),
        _SummaryChip(
          icon: Icons.grid_view_rounded,
          label: l10n.tOr('promoShowing', 'Showing'),
          value: number.format(state.posts.length),
        ),
        if (activeFilters)
          _SummaryChip(
            icon: Icons.filter_alt_outlined,
            label: l10n.tOr('filtersActive', 'Filters active'),
            value: '•',
            emphasize: true,
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = emphasize ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasize
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: emphasize ? scheme.primary : accent),
          const SizedBox(width: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.1,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _PromotedPostsFilters extends StatelessWidget {
  const _PromotedPostsFilters({this.metrics});

  final PromotionsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PromotedPostsBloc, PromotedPostsState,
        PromotedPostsQuery>(
      selector: _queryFrom,
      builder: (context, query) {
        final hasActiveFilters = _promotedPostsHasActiveFilters(query);

        return LayoutBuilder(
          builder: (context, constraints) {
            final m = metrics ??
                PromotionsLayoutMetrics(
                  getPromotionsDeviceType(constraints.maxWidth),
                );
            final narrow = constraints.maxWidth < 720;
            final veryNarrow = constraints.maxWidth < 420;
            final controlHeight = m.filterControlHeight;
            final gap = m.toolbarFilterGap;

            final search = PromotionsToolbarSearchField(
              hint: l10n.t('promoSearchPromotedPosts'),
              initialValue: query.search ?? '',
              height: controlHeight,
              compact: m.isMobile,
              onChanged: (q) => context
                  .read<PromotedPostsBloc>()
                  .add(SearchPromotedPostsEvent(q)),
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
                  .read<PromotedPostsBloc>()
                  .add(FilterPromotedPostsStatusEvent(v)),
            );

            final clearButton = hasActiveFilters
                ? IconButton(
                    tooltip: l10n.t('clearFilters'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context
                        .read<PromotedPostsBloc>()
                        .add(const ClearPromotedPostsFiltersEvent()),
                    icon: Icon(
                      Icons.filter_alt_off_outlined,
                      size: m.isMobile ? 16 : 18,
                      color: scheme.error,
                    ),
                  )
                : null;

            final filtersBody = narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      SizedBox(height: gap),
                      if (veryNarrow)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            status,
                            if (clearButton != null) ...[
                              SizedBox(height: gap),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: clearButton,
                              ),
                            ],
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: status),
                            if (clearButton != null) ...[
                              SizedBox(width: gap),
                              clearButton,
                            ],
                          ],
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 3, child: search),
                      SizedBox(width: gap),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 140,
                          maxWidth: constraints.maxWidth < 1100 ? 168 : 200,
                        ),
                        child: status,
                      ),
                      if (clearButton != null) ...[
                        SizedBox(width: gap),
                        clearButton,
                      ],
                    ],
                  );

            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(m.isMobile ? 8 : 10),
                child: filtersBody,
              ),
            );
          },
        );
      },
    );
  }
}

class _PromotedPostsDataSection extends StatelessWidget {
  const _PromotedPostsDataSection({
    required this.state,
    required this.onOpenAnalytics,
  });

  final PromotedPostsState state;
  final ValueChanged<String> onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = promotionsMetricsOf(context);
    final emptyState =
        state is PromotedPostsEmpty ? state as PromotedPostsEmpty : null;
    final isLoading = state is PromotedPostsInitial ||
        state is PromotedPostsLoading ||
        (emptyState?.isLoading ?? false);
    final errorMessage = switch (state) {
      PromotedPostsError(:final message) => message,
      _ => null,
    };
    final loaded =
        state is PromotedPostsLoaded ? state as PromotedPostsLoaded : null;
    final isEmpty = emptyState != null && !emptyState.isLoading;
    final sortField = _sortFieldFrom(state);
    final query = _queryFrom(state);
    final hasFilters = _promotedPostsHasActiveFilters(query);

    Widget? footer;
    if (loaded != null) {
      if (metrics.useDesktopPagination) {
        footer = PromotionsPaginationBar(
          page: loaded.meta.page,
          totalPages: loaded.meta.totalPages,
          total: loaded.meta.total,
          pageSize: loaded.meta.limit,
          itemCount: loaded.posts.length,
          metrics: metrics,
          showTopBorder: true,
          onPage: (p) => context
              .read<PromotedPostsBloc>()
              .add(LoadPromotedPostsEvent(page: p)),
        );
      } else if (loaded.isLoadingMore) {
        footer = const PromotionsLoadMoreIndicator();
      } else if (loaded.meta.hasReachedMax && loaded.posts.isNotEmpty) {
        footer = const PromotionsEndOfListLabel();
      }
    }

    return PromotionsDataSection(
      footer: footer,
      padding: EdgeInsets.fromLTRB(
        metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg,
        metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg,
        metrics.isMobile ? PromotionsSpace.md : PromotionsSpace.lg,
        PromotionsSpace.md,
      ),
      child: PromotionsDataBody(
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: () => context
            .read<PromotedPostsBloc>()
            .add(const LoadPromotedPostsEvent()),
        isEmpty: isEmpty,
        emptyMessage: hasFilters
            ? l10n.tOr(
                'promoPromotedPostsNoSearchResults',
                'No promoted posts match your search or filters.',
              )
            : l10n.t('noData'),
        emptyIcon: hasFilters
            ? Icons.filter_alt_off_outlined
            : Icons.campaign_outlined,
        minHeight: metrics.isMobile ? 220 : 280,
        child: loaded == null
            ? const SizedBox.shrink()
            : PromotedPostsTable(
                posts: loaded.posts,
                sortField: sortField,
                onSort: (field) => context
                    .read<PromotedPostsBloc>()
                    .add(SortPromotedPostsEvent(field)),
                onViewAnalytics: onOpenAnalytics,
              ),
      ),
    );
  }
}

PromotedPostsQuery _queryFrom(PromotedPostsState state) {
  return switch (state) {
    PromotedPostsLoaded(:final query) => query,
    PromotedPostsEmpty(:final query) => query,
    PromotedPostsLoading(:final query) => query,
    _ => const PromotedPostsQuery(),
  };
}

bool _promotedPostsHasActiveFilters(PromotedPostsQuery query) {
  return (query.search != null && query.search!.isNotEmpty) ||
      (query.status != null && query.status!.isNotEmpty);
}

PromotedPostsSortField _sortFieldFrom(PromotedPostsState state) {
  return switch (state) {
    PromotedPostsLoaded(:final sortField) => sortField,
    PromotedPostsEmpty(:final sortField) => sortField,
    PromotedPostsLoading(:final sortField) => sortField,
    _ => PromotedPostsSortField.views,
  };
}
