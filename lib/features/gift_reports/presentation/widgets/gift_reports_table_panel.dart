import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/gift_report_entities.dart';
import '../../../reports/presentation/utils/reports_responsive.dart';
import '../../../reports/presentation/widgets/reports_pagination_bar.dart';
import '../bloc/gift_reports_bloc.dart';
import '../utils/gift_report_format.dart';
import 'gift_report_range_filters.dart';
import 'gift_reports_pagination_bar.dart';

class GiftReportsTablePanel extends StatefulWidget {
  const GiftReportsTablePanel({
    super.key,
    required this.state,
    required this.searchController,
    this.onRowTap,
    this.hideSearchBar = false,
    this.denseLayout = false,
  });

  final GiftReportsLoaded state;
  final TextEditingController searchController;
  final ValueChanged<String>? onRowTap;
  final bool hideSearchBar;
  final bool denseLayout;

  @override
  State<GiftReportsTablePanel> createState() => _GiftReportsTablePanelState();
}

class _GiftReportsTablePanelState extends State<GiftReportsTablePanel> {
  final _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (!reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width)) return;
    if (!reportsShouldLoadMore(_listScrollController)) return;
    context.read<GiftReportsBloc>().add(LoadMoreGiftReportsEvent());
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GiftReportsFiltersBar(
          state: state,
          searchController: widget.searchController,
          hideSearchBar: widget.hideSearchBar,
          denseLayout: widget.denseLayout,
        ),
        if (widget.denseLayout && state.isListFetching)
          const LinearProgressIndicator(minHeight: 2),
        SizedBox(height: widget.denseLayout ? 6 : 12),
        if (state.listError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.listError!,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _TableHeader(
                    scheme: scheme,
                    compact: reportsMetricsOf(context).isMobile,
                  ),
                  Expanded(
                    child: state.items.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.tOr(
                                'noGiftsFound',
                                'No gifts found',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: _listScrollController,
                            itemCount: state.items.length +
                                (reportsMetricsOf(context).useInfiniteScroll &&
                                        state.isListLoadingMore
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              if (index >= state.items.length) {
                                return const ReportsLoadMoreFooter(
                                  isLoading: true,
                                );
                              }
                              final item = state.items[index];
                              return _GiftReportRow(
                                item: item,
                                compact: reportsMetricsOf(context).isMobile,
                                onTap: widget.onRowTap == null
                                    ? null
                                    : () => widget.onRowTap!(item.id),
                              );
                            },
                          ),
                  ),
                  GiftReportsPaginationBar(
                    currentPage: state.currentPage,
                    lastPage: state.lastPage,
                    total: state.total,
                  ),
                  if (reportsMetricsOf(context).useInfiniteScroll &&
                      state.hasReachedMax &&
                      state.items.isNotEmpty)
                    ReportsLoadMoreFooter(
                      hasReachedMax: true,
                      total: state.total,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftReportsFiltersBar extends StatelessWidget {
  const _GiftReportsFiltersBar({
    required this.state,
    required this.searchController,
    required this.hideSearchBar,
    required this.denseLayout,
  });

  final GiftReportsLoaded state;
  final TextEditingController searchController;
  final bool hideSearchBar;
  final bool denseLayout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<GiftReportsBloc>();

    final hasDateRange = state.fromDate != null || state.toDate != null;
    final hasPriceRange =
        state.minPriceFilter != null || state.maxPriceFilter != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final itemWidth = narrow
            ? (constraints.maxWidth - 8) / 2
            : 118.0;

        Widget slot({required Widget child, bool fullWidth = false}) {
          if (fullWidth && narrow) {
            return SizedBox(width: constraints.maxWidth, child: child);
          }
          return SizedBox(width: itemWidth, child: child);
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!hideSearchBar)
              SizedBox(
                width: narrow ? constraints.maxWidth : 240,
                height: 34,
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.t('searchGifts'),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  onChanged: (value) =>
                      bloc.add(UpdateGiftReportsSearchEvent(value)),
                ),
              ),
            slot(
              child: _CompactDropdown<bool?>(
                value: state.isActiveFilter,
                hint: l10n.t('status'),
                items: [
                  (label: l10n.t('filterAll'), value: null),
                  (label: l10n.t('active'), value: true),
                  (label: l10n.t('inactive'), value: false),
                ],
                onChanged: (value) =>
                    bloc.add(UpdateGiftReportsActiveFilterEvent(value)),
              ),
            ),
            slot(
              child: GiftReportRangeFilterButton(
                dense: true,
                icon: Icons.attach_money_rounded,
                label: giftReportPriceRangeLabel(
                  context,
                  minPrice: state.minPriceFilter,
                  maxPrice: state.maxPriceFilter,
                ),
                hasRange: hasPriceRange,
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: GiftReportPriceRangeDialog(
                        initialMin: state.minPriceFilter,
                        initialMax: state.maxPriceFilter,
                        onApply: (min, max) => bloc.add(
                          UpdateGiftReportsPriceRangeFilterEvent(
                            minPrice: min,
                            maxPrice: max,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onClear: hasPriceRange
                    ? () => bloc.add(
                          UpdateGiftReportsPriceRangeFilterEvent(
                            minPrice: null,
                            maxPrice: null,
                          ),
                        )
                    : null,
              ),
            ),
            slot(
              child: GiftReportRangeFilterButton(
                dense: true,
                label: giftReportDateRangeLabel(
                  context,
                  fromDate: state.fromDate,
                  toDate: state.toDate,
                ),
                hasRange: hasDateRange,
                onTap: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => GiftReportDateRangeDialog(
                      initialFrom: state.fromDate,
                      initialTo: state.toDate,
                      onApply: (from, to) => bloc.add(
                        SetGiftReportsDateRangeFilterEvent(
                          fromDate: from,
                          toDate: to,
                        ),
                      ),
                    ),
                  );
                },
                onClear: hasDateRange
                    ? () => bloc.add(
                          SetGiftReportsDateRangeFilterEvent(
                            fromDate: null,
                            toDate: null,
                          ),
                        )
                    : null,
              ),
            ),
            slot(
              child: _CompactDropdown<GiftReportsSort>(
                value: state.sort,
                hint: l10n.t('sortBy'),
                items: [
                  (label: 'New Gifts', value: GiftReportsSort.newest),
                  (label: 'Old Gifts', value: GiftReportsSort.oldest),
                  (label: l10n.t('sortMostViewed'), value: GiftReportsSort.mostSent),
                  (label: l10n.t('sortHighestBid'), value: GiftReportsSort.mostRevenue),
                  (label: l10n.t('priceLowToHigh'), value: GiftReportsSort.priceAsc),
                  (label: l10n.t('priceHighToLow'), value: GiftReportsSort.priceDesc),
                  (label: l10n.t('categorySortName'), value: GiftReportsSort.name),
                ],
                onChanged: (sort) {
                  if (sort != null) {
                    bloc.add(UpdateGiftReportsSortEvent(sort));
                  }
                },
              ),
            ),
            if (state.isListFetching)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<({String label, T? value})> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<T>(
        value: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        style: TextStyle(fontSize: 12, color: scheme.onSurface),
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.value,
                child: Text(
                  e.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.scheme,
    this.compact = false,
  });

  final ColorScheme scheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox.shrink();
    final l10n = context.l10n;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 3, child: Text(l10n.t('gifts'), style: style)),
          Expanded(child: Text(l10n.t('priceRange'), style: style)),
          Expanded(child: Text(l10n.t('giftReportPeriodSends'), style: style)),
          Expanded(child: Text(l10n.t('giftReportRevenue'), style: style)),
          Expanded(child: Text(l10n.t('status'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _GiftReportRow extends StatelessWidget {
  const _GiftReportRow({
    required this.item,
    this.onTap,
    this.compact = false,
  });

  final GiftReportListItemEntity item;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final thumbSize = compact ? 32.0 : 36.0;

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
              return;
            }
            Navigator.of(context).pushNamed(
              AppRoutes.giftReportDetail,
              arguments: item.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl,
                          width: thumbSize,
                          height: thumbSize,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _thumbFallback(scheme),
                        )
                      : _thumbFallback(scheme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${formatReportCoins(item.priceCoins)} · ${formatReportCount(item.counts.transactions)} sends',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          Navigator.of(context).pushNamed(
            AppRoutes.giftReportDetail,
            arguments: item.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbFallback(scheme),
                      )
                    : _thumbFallback(scheme),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatReportDate(item.publishedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(formatReportCoins(item.priceCoins)),
              ),
              Expanded(
                child: Text(formatReportCount(item.counts.transactions)),
              ),
              Expanded(
                child: Text(formatReportCoins(item.revenue.spendCoins)),
              ),
              Expanded(
                child: _StatusBadge(
                  isActive: item.isActive,
                  activeLabel: l10n.t('active'),
                  inactiveLabel: l10n.t('inactive'),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback(ColorScheme scheme) {
    return Container(
      width: 36,
      height: 36,
      color: scheme.primaryContainer,
      child: Icon(Icons.card_giftcard, size: 18, color: scheme.primary),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isActive,
    required this.activeLabel,
    required this.inactiveLabel,
  });

  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? activeLabel : inactiveLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
      ),
    );
  }
}
