import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/search_management_entities.dart';
import '../bloc/search_management_bloc.dart';
import '../bloc/search_management_event.dart';
import '../bloc/search_management_state.dart';
import '../utils/search_management_responsive.dart';
import 'search_management_date_range_dialog.dart';

/// Compact filter toolbar matching [LocationToolbar] / Search History style.
class SearchManagementFiltersBar extends StatefulWidget {
  const SearchManagementFiltersBar({super.key, this.metrics});

  final SearchManagementLayoutMetrics? metrics;

  static const controlHeight = ToolbarFilterStyle.controlHeight;
  static const dropdownWidth = 128.0;
  static const dateWidth = 156.0;

  @override
  State<SearchManagementFiltersBar> createState() =>
      _SearchManagementFiltersBarState();
}

class _SearchManagementFiltersBarState
    extends State<SearchManagementFiltersBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context
          .read<SearchManagementBloc>()
          .add(SearchManagementQueryChangedEvent(value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<SearchManagementBloc, SearchManagementState,
        SearchManagementFilterQuery?>(
      selector: (state) =>
          state is SearchManagementLoaded ? state.filter : null,
      builder: (context, filter) {
        if (filter == null) return const SizedBox.shrink();

        final hasActiveFilters = filter.hasActiveFilters;

        final searchField = _CompactSearchField(
          hint: l10n.tOr(
            'searchMgmtSearchPlaceholder',
            'Search queries, users, sounds…',
          ),
          initialValue: filter.q,
          onChanged: _onSearchChanged,
        );

        final categoryDropdown = _CompactFilterDropdown<SearchApiTab>(
          hint: l10n.tOr('searchMgmtCategory', 'Category'),
          value: filter.apiTab,
          items: SearchApiTab.values,
          itemLabel: (v) => v.apiValue,
          onChanged: (v) {
            if (v == null) return;
            context
                .read<SearchManagementBloc>()
                .add(SearchManagementCategoryChangedEvent(v));
          },
        );

        final sortDropdown = _CompactFilterDropdown<SearchManagementSort>(
          hint: l10n.tOr('sort', 'Sort'),
          value: filter.sort,
          items: SearchManagementSort.values,
          itemLabel: (v) => switch (v) {
            SearchManagementSort.relevance =>
              l10n.tOr('searchMgmtSortRelevance', 'Relevance'),
            SearchManagementSort.newest =>
              l10n.tOr('searchMgmtSortNewest', 'Newest'),
            SearchManagementSort.oldest =>
              l10n.tOr('searchMgmtSortOldest', 'Oldest'),
            SearchManagementSort.popularity =>
              l10n.tOr('searchMgmtSortPopular', 'Popularity'),
          },
          onChanged: (v) {
            if (v == null) return;
            context
                .read<SearchManagementBloc>()
                .add(SearchManagementSortChangedEvent(v));
          },
        );

        final dateFilter = _CompactDateRangeFilter(
          from: filter.from,
          to: filter.to,
          onChanged: (from, to, {required bool clear}) {
            context.read<SearchManagementBloc>().add(
                  SearchManagementDateChangedEvent(
                    from: from,
                    to: to,
                    clear: clear,
                  ),
                );
          },
        );

        final trendingChip = FilterChip(
          label: Text(
            l10n.tOr('searchMgmtTrendingOnly', 'Trending'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          selected: filter.trendingOnly,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          onSelected: (v) => context
              .read<SearchManagementBloc>()
              .add(SearchManagementTrendingFilterChangedEvent(v)),
        );

        final clearButton = hasActiveFilters
            ? IconButton(
                tooltip: l10n.tOr('searchMgmtResetFilters', 'Reset'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => context
                    .read<SearchManagementBloc>()
                    .add(const SearchManagementFilterResetEvent()),
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: 17,
                  color: scheme.error,
                ),
              )
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final m = widget.metrics ??
                SearchManagementLayoutMetrics(
                  getSearchManagementDeviceType(constraints.maxWidth),
                );
            final gap = m.toolbarFilterGap;
            final controlHeight = m.toolbarControlHeight;
            final veryNarrow = constraints.maxWidth < 520;
            final narrow = constraints.maxWidth < 760;
            final medium = constraints.maxWidth < 1120;

            Widget sized(Widget child, {double? width}) {
              return SizedBox(
                width: width,
                height: controlHeight,
                child: child,
              );
            }

            Widget filterRow({
              required List<Widget> filters,
              bool inlineClear = false,
            }) {
              return Row(
                children: [
                  for (var i = 0; i < filters.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(child: sized(filters[i])),
                  ],
                  if (inlineClear && clearButton != null) ...[
                    SizedBox(width: gap),
                    clearButton,
                  ],
                ],
              );
            }

            if (veryNarrow || narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sized(searchField),
                  SizedBox(height: gap),
                  filterRow(
                    filters: [categoryDropdown, sortDropdown],
                    inlineClear: true,
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(child: sized(dateFilter)),
                      SizedBox(width: gap),
                      trendingChip,
                    ],
                  ),
                ],
              );
            }

            if (medium) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: sized(searchField),
                  ),
                  SizedBox(width: gap),
                  Expanded(child: sized(categoryDropdown)),
                  SizedBox(width: gap),
                  Expanded(child: sized(sortDropdown)),
                  SizedBox(width: gap),
                  Expanded(flex: 2, child: sized(dateFilter)),
                  SizedBox(width: gap),
                  trendingChip,
                  ?clearButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: sized(searchField),
                ),
                SizedBox(width: gap),
                sized(
                  categoryDropdown,
                  width: SearchManagementFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sized(
                  sortDropdown,
                  width: SearchManagementFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sized(
                  dateFilter,
                  width: SearchManagementFiltersBar.dateWidth,
                ),
                SizedBox(width: gap),
                trendingChip,
                ?clearButton,
              ],
            );
          },
        );
      },
    );
  }
}

class _CompactSearchField extends StatefulWidget {
  const _CompactSearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<_CompactSearchField> createState() => _CompactSearchFieldState();
}

class _CompactSearchFieldState extends State<_CompactSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_CompactSearchField oldWidget) {
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
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: _controller,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
      textInputAction: TextInputAction.search,
      decoration: ToolbarFilterStyle.inputDecoration(
        scheme,
        hintText: widget.hint,
        hintStyle: textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _CompactFilterDropdown<T> extends StatelessWidget {
  const _CompactFilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      height: ToolbarFilterStyle.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: [
            for (final v in items)
              DropdownMenuItem(
                value: v,
                child: Text(
                  itemLabel(v),
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

enum _DatePreset { all, today, last7, last30, custom }

class _CompactDateRangeFilter extends StatelessWidget {
  const _CompactDateRangeFilter({
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to, {required bool clear})
      onChanged;

  static const _controlHeight = ToolbarFilterStyle.controlHeight;

  bool get _hasRange => from != null && to != null;

  _DatePreset _activePreset() {
    if (!_hasRange) return _DatePreset.all;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    if (_sameDay(from!, startOfToday)) return _DatePreset.today;
    if (_sameDay(from!, now.subtract(const Duration(days: 7)))) {
      return _DatePreset.last7;
    }
    if (_sameDay(from!, now.subtract(const Duration(days: 30)))) {
      return _DatePreset.last30;
    }
    return _DatePreset.custom;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickCustom(BuildContext context) async {
    final result = await showSearchManagementDateRangeDialog(
      context,
      initialFrom: from,
      initialTo: to,
    );
    if (result == null) return;
    if (result.clear) {
      onChanged(null, null, clear: true);
      return;
    }
    final range = result.range;
    if (range == null) return;
    onChanged(range.start, range.end, clear: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final preset = _activePreset();
    final isActive = preset != _DatePreset.all;

    final label = switch (preset) {
      _DatePreset.today => l10n.tOr('promoDateRangeToday', 'Today'),
      _DatePreset.last7 => l10n.tOr('promoDateRange7Days', 'Last 7 days'),
      _DatePreset.last30 => l10n.tOr('promoDateRange30Days', 'Last 30 days'),
      _DatePreset.custom when _hasRange =>
        '${DateFormat.MMMd().format(from!)} – ${DateFormat.MMMd().format(to!)}',
      _DatePreset.custom => l10n.tOr('promoDateRangeCustom', 'Custom'),
      _DatePreset.all => l10n.tOr('searchMgmtDateRange', 'Date'),
    };

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ToolbarFilterStyle.radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<_DatePreset>(
        tooltip: l10n.tOr('searchMgmtDateRange', 'Date'),
        offset: const Offset(0, _controlHeight),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          final now = DateTime.now();
          switch (value) {
            case _DatePreset.all:
              onChanged(null, null, clear: true);
            case _DatePreset.today:
              onChanged(
                DateTime(now.year, now.month, now.day),
                now,
                clear: false,
              );
            case _DatePreset.last7:
              onChanged(
                now.subtract(const Duration(days: 7)),
                now,
                clear: false,
              );
            case _DatePreset.last30:
              onChanged(
                now.subtract(const Duration(days: 30)),
                now,
                clear: false,
              );
            case _DatePreset.custom:
              _pickCustom(context);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _DatePreset.all,
            child: Text(l10n.tOr('all', 'All')),
          ),
          PopupMenuItem(
            value: _DatePreset.today,
            child: Text(l10n.tOr('promoDateRangeToday', 'Today')),
          ),
          PopupMenuItem(
            value: _DatePreset.last7,
            child: Text(l10n.tOr('promoDateRange7Days', 'Last 7 days')),
          ),
          PopupMenuItem(
            value: _DatePreset.last30,
            child: Text(l10n.tOr('promoDateRange30Days', 'Last 30 days')),
          ),
          PopupMenuItem(
            value: _DatePreset.custom,
            child: Text(l10n.tOr('promoDateRangeCustom', 'Custom')),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                Icons.date_range_outlined,
                size: 16,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
