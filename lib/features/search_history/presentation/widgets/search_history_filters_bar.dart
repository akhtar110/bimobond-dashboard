import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/search_history.dart';
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import '../bloc/search_history_state.dart';
import '../utils/search_history_responsive.dart';
import 'search_history_date_range_dialog.dart';

class SearchHistoryFiltersBar extends StatefulWidget {
  const SearchHistoryFiltersBar({
    super.key,
    this.embedded = false,
    this.metrics,
  });

  final bool embedded;
  final SearchHistoryLayoutMetrics? metrics;

  static const controlHeight = ToolbarFilterStyle.controlHeight;
  static const dropdownWidth = 148.0;
  static const dateButtonWidth = 168.0;

  @override
  State<SearchHistoryFiltersBar> createState() =>
      _SearchHistoryFiltersBarState();
}

class _SearchHistoryFiltersBarState extends State<SearchHistoryFiltersBar> {
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
      final trimmed = value.trim();
      context.read<SearchHistoryBloc>().add(
            UpdateFilters(
              search: trimmed,
              clearSearch: trimmed.isEmpty,
            ),
          );
    });
  }

  Future<void> _pickDateRange(SearchHistoryQuery query) async {
    final result = await showSearchHistoryDateRangeDialog(
      context,
      initialFrom: query.from,
      initialTo: query.to,
    );
    if (result == null || !mounted) return;

    if (result.clear) {
      context.read<SearchHistoryBloc>().add(
            const UpdateFilters(clearDateRange: true),
          );
      return;
    }

    if (result.range != null) {
      context.read<SearchHistoryBloc>().add(
            UpdateFilters(dateRange: result.range),
          );
    }
  }

  String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<SearchHistoryBloc, SearchHistoryState, SearchHistoryQuery?>(
      selector: (state) => state is SearchHistoryLoaded ? state.query : null,
      builder: (context, query) {
        if (query == null) {
          return const SizedBox.shrink();
        }

        final hasActiveFilters = query.hasActiveFilters;
        final hasDateRange = query.from != null && query.to != null;
        final dateLabel = hasDateRange
            ? '${_fmtDate(query.from!)} – ${_fmtDate(query.to!)}'
            : l10n.t('dateRange');

        final searchField = _SearchHistorySearchField(
          hint: l10n.tOr('searchHistorySearchPlaceholder', 'Search queries…'),
          initialValue: query.search ?? '',
          onChanged: _onSearchChanged,
        );

        final categoryDropdown = _SearchHistoryFilterDropdown(
          hint: l10n.tOr('searchHistoryCategory', 'Category'),
          value: query.category,
          items: [null, ...SearchHistoryCategories.filterOptions],
          itemLabel: (v) =>
              v == null ? l10n.t('all') : _categoryLabel(l10n, v),
          onChanged: (v) => context
              .read<SearchHistoryBloc>()
              .add(UpdateFilters(category: v)),
        );

        final sortDropdown = _SearchHistoryFilterDropdown(
          hint: l10n.tOr('sort', 'Sort'),
          value: query.sort.apiValue,
          items: SearchHistorySort.values.map((s) => s.apiValue).toList(),
          itemLabel: (v) => _sortLabel(context, v),
          onChanged: (v) {
            final sort = SearchHistorySort.values.firstWhere(
              (s) => s.apiValue == v,
              orElse: () => SearchHistorySort.newest,
            );
            context.read<SearchHistoryBloc>().add(UpdateFilters(sort: sort));
          },
        );

        final dateButton = _SearchHistoryDateRangeButton(
          label: dateLabel,
          hasRange: hasDateRange,
          onTap: () => _pickDateRange(query),
          onClear: hasDateRange
              ? () => context.read<SearchHistoryBloc>().add(
                    const UpdateFilters(clearDateRange: true),
                  )
              : null,
        );

        final clearButton = hasActiveFilters
            ? IconButton(
                tooltip: l10n.tOr('searchHistoryClearFilters', 'Clear filters'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => context
                    .read<SearchHistoryBloc>()
                    .add(const ClearFilters()),
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: 17,
                  color: scheme.error,
                ),
              )
            : null;

        if (widget.embedded) {
          final controlHeight = widget.metrics?.toolbarControlHeight ??
              SearchHistoryFiltersBar.controlHeight;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: controlHeight,
                  child: categoryDropdown,
                ),
              ),
              if (clearButton != null) clearButton,
            ],
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final m = widget.metrics ??
                SearchHistoryLayoutMetrics(
                  getSearchHistoryDeviceType(constraints.maxWidth),
                );
            final gap = m.toolbarFilterGap;
            final controlHeight = m.toolbarControlHeight;
            final veryNarrow = constraints.maxWidth < 520;
            final narrow = constraints.maxWidth < 760;
            final medium = constraints.maxWidth < 1120;

            Widget sizedFilter(Widget filter, {double? width}) {
              return SizedBox(
                width: width,
                height: controlHeight,
                child: filter,
              );
            }

            Widget filterRow({
              required List<Widget> filters,
              bool inlineClear = false,
            }) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < filters.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(child: sizedFilter(filters[i])),
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
                  SizedBox(height: controlHeight, child: searchField),
                  SizedBox(height: gap),
                  filterRow(
                    filters: [categoryDropdown, sortDropdown],
                    inlineClear: true,
                  ),
                  SizedBox(height: gap),
                  sizedFilter(dateButton),
                ],
              );
            }

            if (medium) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: SizedBox(height: controlHeight, child: searchField)),
                  SizedBox(width: gap),
                  Expanded(child: sizedFilter(categoryDropdown)),
                  SizedBox(width: gap),
                  Expanded(child: sizedFilter(sortDropdown)),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: sizedFilter(dateButton),
                  ),
                  if (clearButton != null) clearButton,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(height: controlHeight, child: searchField),
                ),
                SizedBox(width: gap),
                sizedFilter(
                  categoryDropdown,
                  width: SearchHistoryFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sizedFilter(
                  sortDropdown,
                  width: SearchHistoryFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sizedFilter(
                  dateButton,
                  width: SearchHistoryFiltersBar.dateButtonWidth,
                ),
                if (clearButton != null) clearButton,
              ],
            );
          },
        );
      },
    );
  }

  String _categoryLabel(dynamic l10n, String category) {
    return switch (category) {
      SearchHistoryCategories.posts => l10n.t('posts'),
      SearchHistoryCategories.users => l10n.t('users'),
      SearchHistoryCategories.hashtags => l10n.tOr('hashtags', 'Hashtags'),
      SearchHistoryCategories.sounds => l10n.tOr('soundManagement', 'Sounds'),
      SearchHistoryCategories.auctions => l10n.t('auctions'),
      SearchHistoryCategories.lives => l10n.tOr('lives', 'Lives'),
      SearchHistoryCategories.chats => l10n.t('chatManagement'),
      _ => category,
    };
  }

  String _sortLabel(BuildContext context, String? value) {
    final l10n = context.l10n;
    final sort = SearchHistorySort.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => SearchHistorySort.newest,
    );
    return switch (sort) {
      SearchHistorySort.newest =>
        context.isRtl ? 'حديث' : 'Recent',
      SearchHistorySort.oldest =>
        context.isRtl ? 'قديم' : 'Old',
      SearchHistorySort.queryAsc =>
        l10n.tOr('searchHistorySortQueryAsc', 'Query A–Z'),
      SearchHistorySort.queryDesc =>
        l10n.tOr('searchHistorySortQueryDesc', 'Query Z–A'),
    };
  }
}

class _SearchHistorySearchField extends StatefulWidget {
  const _SearchHistorySearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<_SearchHistorySearchField> createState() =>
      _SearchHistorySearchFieldState();
}

class _SearchHistorySearchFieldState extends State<_SearchHistorySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_SearchHistorySearchField oldWidget) {
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

    return SizedBox(
      height: SearchHistoryFiltersBar.controlHeight,
      child: TextField(
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
      ),
    );
  }
}

class _SearchHistoryFilterDropdown extends StatelessWidget {
  const _SearchHistoryFilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      height: SearchHistoryFiltersBar.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
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
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
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

class _SearchHistoryDateRangeButton extends StatelessWidget {
  const _SearchHistoryDateRangeButton({
    required this.label,
    required this.hasRange,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool hasRange;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ToolbarFilterStyle.radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: SearchHistoryFiltersBar.controlHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: hasRange ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: hasRange
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight:
                          hasRange ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: context.l10n.t('clear'),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
