import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/promoted_posts_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/promoted_post_analytics_sheet.dart';
import '../widgets/promotions_dashboard_widgets.dart';
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
                    const LinearProgressIndicator(),
                  ],
                  SizedBox(
                    height: metrics.isMobile
                        ? PromotionsSpace.md
                        : PromotionsSpace.lg,
                  ),
                  _PromotedPostsBody(
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

            final search = _PromotedPostsSearchField(
              hint: l10n.t('promoSearchPromotedPosts'),
              initialValue: query.search ?? '',
              height: controlHeight,
              compact: metrics.isMobile,
              onChanged: (q) => context
                  .read<PromotedPostsBloc>()
                  .add(SearchPromotedPostsEvent(q)),
            );

            final status = SizedBox(
              height: controlHeight,
              child: _StatusDropdown(query: query, compact: metrics.isMobile),
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

class _PromotedPostsSearchField extends StatefulWidget {
  const _PromotedPostsSearchField({
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
  State<_PromotedPostsSearchField> createState() =>
      _PromotedPostsSearchFieldState();
}

class _PromotedPostsSearchFieldState extends State<_PromotedPostsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_PromotedPostsSearchField oldWidget) {
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

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: widget.compact ? 12 : null,
            ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
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
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.query, this.compact = false});

  final PromotedPostsQuery query;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final safeValue = query.status;
    final items = [null, ...CampaignStatus.values.map((s) => s.apiValue)];

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
          value: items.contains(safeValue) ? safeValue : null,
          isExpanded: true,
          isDense: true,
          hint: Text(
            l10n.t('status'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    v == null
                        ? l10n.t('all')
                        : switch (CampaignStatus.tryParse(v)) {
                            CampaignStatus.pendingPayment =>
                              l10n.t('promoStatusPendingPayment'),
                            CampaignStatus.active =>
                              l10n.t('promoStatusActive'),
                            CampaignStatus.paused =>
                              l10n.t('promoStatusPaused'),
                            CampaignStatus.completed =>
                              l10n.t('promoStatusCompleted'),
                            CampaignStatus.cancelled =>
                              l10n.t('promoStatusCancelled'),
                            CampaignStatus.rejected =>
                              l10n.t('promoStatusRejected'),
                            _ => v,
                          },
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => context
              .read<PromotedPostsBloc>()
              .add(FilterPromotedPostsStatusEvent(v)),
        ),
      ),
    );
  }
}

class _PromotedPostsBody extends StatelessWidget {
  const _PromotedPostsBody({
    required this.state,
    required this.onOpenAnalytics,
  });

  final PromotedPostsState state;
  final ValueChanged<String> onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sortField = _sortFieldFrom(state);

    return switch (state) {
      PromotedPostsError(:final message) => _PageStateBox(
          child: ErrorView(
            message: message,
            retryLabel: l10n.t('retry'),
            onRetry: () => context
                .read<PromotedPostsBloc>()
                .add(const LoadPromotedPostsEvent()),
          ),
        ),
      PromotedPostsInitial() ||
      PromotedPostsLoading() ||
      PromotedPostsEmpty(isLoading: true) =>
        const _PageStateBox(child: LoadingView()),
      PromotedPostsEmpty() => _PageStateBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: PromotionsSpace.lg),
              Text(
                l10n.t('promoNoPromotedPosts'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: PromotionsSpace.sm),
              Text(
                l10n.t('promoNoPromotedPostsHint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      PromotedPostsLoaded(:final posts, :final meta, :final isLoadingMore) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PromotedPostsTable(
              posts: posts,
              sortField: sortField,
              onSort: (field) => context
                  .read<PromotedPostsBloc>()
                  .add(SortPromotedPostsEvent(field)),
              onViewAnalytics: onOpenAnalytics,
              onViewHistory: onOpenAnalytics,
            ),
            if (promotionsMetricsOf(context).useDesktopPagination) ...[
              const SizedBox(height: PromotionsSpace.lg),
              PromotionsPaginationBar(
                page: meta.page,
                totalPages: meta.totalPages,
                total: meta.total,
                metrics: promotionsMetricsOf(context),
                onPage: (p) => context
                    .read<PromotedPostsBloc>()
                    .add(LoadPromotedPostsEvent(page: p)),
              ),
            ] else ...[
              if (isLoadingMore)
                const PromotionsLoadMoreFooter(isLoading: true),
              if (meta.hasReachedMax && posts.isNotEmpty)
                PromotionsLoadMoreFooter(
                  hasReachedMax: true,
                  total: meta.total,
                ),
            ],
          ],
        ),
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
      height: 320,
      child: Center(child: child),
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
