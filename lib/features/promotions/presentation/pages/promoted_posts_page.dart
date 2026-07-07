import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final l10n = context.l10n;

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
                    l10n.t('promoPromotedPostsTitle'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: metrics.isMobile ? 20 : null,
                        ),
                  ),
                  SizedBox(height: metrics.sectionGap),
                  const _PromotedPostsFilters(),
                  if (showProgress) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(
                    height: metrics.isMobile
                        ? PromotionsSpace.md
                        : PromotionsSpace.lg,
                  ),
                  _PromotedPostsDataSection(
                    state: state,
                    onOpenAnalytics: (postId) => _openAnalytics(context, postId),
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

class _PromotedPostsFilters extends StatelessWidget {
  const _PromotedPostsFilters();

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
            final metrics = PromotionsLayoutMetrics(
              getPromotionsDeviceType(constraints.maxWidth),
            );
            final narrow = constraints.maxWidth < 720;
            final controlHeight = metrics.filterControlHeight;

            final search = PromotionsToolbarSearchField(
              hint: l10n.t('promoSearchPromotedPosts'),
              initialValue: query.search ?? '',
              height: controlHeight,
              compact: metrics.isMobile,
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
                  width: metrics.isMobile ? 140 : 160,
                  child: status,
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

    Widget? footer;
    if (loaded != null) {
      if (promotionsMetricsOf(context).useDesktopPagination) {
        footer = PromotionsPaginationBar(
          page: loaded.meta.page,
          totalPages: loaded.meta.totalPages,
          total: loaded.meta.total,
          metrics: promotionsMetricsOf(context),
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
      child: PromotionsDataBody(
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: () => context
            .read<PromotedPostsBloc>()
            .add(const LoadPromotedPostsEvent()),
        isEmpty: isEmpty,
        emptyMessage: l10n.t('noData'),
        child: loaded == null
            ? const SizedBox.shrink()
            : PromotedPostsTable(
                posts: loaded.posts,
                sortField: sortField,
                onSort: (field) => context
                    .read<PromotedPostsBloc>()
                    .add(SortPromotedPostsEvent(field)),
                onViewAnalytics: onOpenAnalytics,
                onViewHistory: onOpenAnalytics,
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
