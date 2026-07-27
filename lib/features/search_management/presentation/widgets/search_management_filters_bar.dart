import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_button.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_header.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../../domain/entities/search_management_entities.dart';
import '../bloc/search_management_bloc.dart';
import '../bloc/search_management_event.dart';
import '../bloc/search_management_state.dart';
import '../utils/search_management_responsive.dart';
import 'search_management_date_range_dialog.dart';

/// Count of advanced filters only (search text lives in the search field).
int searchManagementAppliedFilterCount(SearchManagementFilterQuery filter) {
  var n = 0;
  if (filter.apiTab != SearchApiTab.best) n++;
  if (filter.from != null || filter.to != null) n++;
  if (filter.sort != SearchManagementSort.relevance) n++;
  if (filter.trendingOnly) n++;
  return n;
}

/// Gifts-style filter bar: search + Filters button on one horizontal row.
class SearchManagementFiltersBar extends StatefulWidget {
  const SearchManagementFiltersBar({super.key, this.metrics});

  final SearchManagementLayoutMetrics? metrics;

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

    return BlocSelector<SearchManagementBloc, SearchManagementState,
        SearchManagementFilterQuery?>(
      selector: (state) =>
          state is SearchManagementLoaded ? state.filter : null,
      builder: (context, filter) {
        if (filter == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final m = widget.metrics ??
                SearchManagementLayoutMetrics(
                  getSearchManagementDeviceType(constraints.maxWidth),
                );
            final height = m.toolbarControlHeight;
            final gap = m.isMobile ? 8.0 : 10.0;
            final activeCount = searchManagementAppliedFilterCount(filter);

            return SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CompactSearchField(
                      hint: l10n.tOr(
                        'searchMgmtSearchPlaceholder',
                        'Search queries, users, sounds…',
                      ),
                      initialValue: filter.q,
                      height: height,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  SizedBox(width: gap),
                  Builder(
                    builder: (buttonContext) {
                      return GiftsFilterButton(
                        activeCount: activeCount,
                        height: height,
                        onPressed: () {
                          final box =
                              buttonContext.findRenderObject() as RenderBox?;
                          final origin =
                              box?.localToGlobal(Offset.zero) ?? Offset.zero;
                          final size = box?.size ?? Size.zero;
                          showSearchManagementFilterPopup(
                            context: buttonContext,
                            filter: filter,
                            anchorRect: Rect.fromLTWH(
                              origin.dx,
                              origin.dy,
                              size.width,
                              size.height,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
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
    required this.height,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final double height;
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

    return SizedBox(
      height: widget.height,
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
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(widget.height - 4, widget.height - 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
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
        ).copyWith(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          prefixIconConstraints: BoxConstraints(
            minWidth: widget.height,
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
          suffixIconConstraints: BoxConstraints(
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
        ),
      ),
    );
  }
}

Future<void> showSearchManagementFilterPopup({
  required BuildContext context,
  required SearchManagementFilterQuery filter,
  required Rect anchorRect,
}) {
  final bloc = context.read<SearchManagementBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<SearchManagementBloc>.value(
        value: bloc,
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          _SearchManagementFilterPopup(
            filter: filter,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            _SearchManagementFilterPopup(
              filter: filter,
              width: 380,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 380.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.68;
  if (top + 320 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 320.0);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: wrap(
                _SearchManagementFilterPopup(
                  filter: filter,
                  width: panelWidth,
                  maxHeight: maxPanelHeight,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SearchManagementFilterPopup extends StatefulWidget {
  const _SearchManagementFilterPopup({
    required this.filter,
    this.width,
    this.maxHeight = 480,
    this.borderRadius,
  });

  final SearchManagementFilterQuery filter;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;

  @override
  State<_SearchManagementFilterPopup> createState() =>
      _SearchManagementFilterPopupState();
}

class _SearchManagementFilterPopupState
    extends State<_SearchManagementFilterPopup> {
  late SearchApiTab _apiTab;
  late SearchManagementSort _sort;
  late bool _trendingOnly;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.filter);
  }

  void _syncFrom(SearchManagementFilterQuery filter) {
    _apiTab = filter.apiTab;
    _sort = filter.sort;
    _trendingOnly = filter.trendingOnly;
    _from = filter.from;
    _to = filter.to;
  }

  void _reset() {
    setState(() {
      _apiTab = SearchApiTab.best;
      _sort = SearchManagementSort.relevance;
      _trendingOnly = false;
      _from = null;
      _to = null;
    });
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _apply() {
    context.read<SearchManagementBloc>().add(
          SearchManagementFilterAppliedEvent(
            filter: SearchManagementFilterQuery(
              q: widget.filter.q,
              apiTab: _apiTab,
              sort: _sort,
              trendingOnly: _trendingOnly,
              from: _from,
              to: _to,
              page: 1,
              limit: widget.filter.limit,
            ),
          ),
        );
    _close();
  }

  Future<void> _pickCustomDate() async {
    final result = await showSearchManagementDateRangeDialog(
      context,
      initialFrom: _from,
      initialTo: _to,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.clear) {
        _from = null;
        _to = null;
      } else {
        _from = result.range?.start;
        _to = result.range?.end;
      }
    });
  }

  String _sortLabel(AppLocalizations l10n, SearchManagementSort sort) {
    return switch (sort) {
      SearchManagementSort.relevance =>
        l10n.tOr('searchMgmtSortRelevance', 'Relevance'),
      SearchManagementSort.newest =>
        l10n.tOr('searchMgmtSortNewest', 'Newest'),
      SearchManagementSort.oldest =>
        l10n.tOr('searchMgmtSortOldest', 'Oldest'),
      SearchManagementSort.popularity =>
        l10n.tOr('searchMgmtSortPopular', 'Popularity'),
    };
  }

  String _dateLabel(AppLocalizations l10n) {
    if (_from == null || _to == null) {
      return l10n.tOr('all', 'All');
    }
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(_from!, startOfToday)) {
      return l10n.tOr('promoDateRangeToday', 'Today');
    }
    if (sameDay(_from!, now.subtract(const Duration(days: 7)))) {
      return l10n.tOr('promoDateRange7Days', 'Last 7 days');
    }
    if (sameDay(_from!, now.subtract(const Duration(days: 30)))) {
      return l10n.tOr('promoDateRange30Days', 'Last 30 days');
    }
    return '${DateFormat.MMMd().format(_from!)} – ${DateFormat.MMMd().format(_to!)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    final activeItems = <GiftsActiveFilterItem>[
      if (_apiTab != SearchApiTab.best)
        GiftsActiveFilterItem(
          id: 'category',
          label: _apiTab.apiValue,
          onRemove: () => setState(() => _apiTab = SearchApiTab.best),
        ),
      if (_sort != SearchManagementSort.relevance)
        GiftsActiveFilterItem(
          id: 'sort',
          label: _sortLabel(l10n, _sort),
          onRemove: () =>
              setState(() => _sort = SearchManagementSort.relevance),
        ),
      if (_from != null || _to != null)
        GiftsActiveFilterItem(
          id: 'date',
          label: _dateLabel(l10n),
          onRemove: () => setState(() {
            _from = null;
            _to = null;
          }),
        ),
      if (_trendingOnly)
        GiftsActiveFilterItem(
          id: 'trending',
          label: l10n.tOr('searchMgmtTrendingOnly', 'Trending'),
          onRemove: () => setState(() => _trendingOnly = false),
        ),
    ];

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.width ?? 380,
        height: widget.maxHeight,
        child: Column(
          children: [
            GiftsFilterHeader(onResetAll: _reset, onClose: _close),
            if (activeItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: GiftsActiveFilters(items: activeItems),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  GiftsFilterSection(
                    title: l10n
                        .tOr('searchMgmtCategory', 'Category')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final tab in SearchApiTab.values)
                          GiftsFilterChoiceChip(
                            label: tab.apiValue,
                            selected: _apiTab == tab,
                            onTap: () => setState(() => _apiTab = tab),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('sort', 'Sort').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final sort in SearchManagementSort.values)
                          GiftsFilterChoiceChip(
                            label: _sortLabel(l10n, sort),
                            selected: _sort == sort,
                            onTap: () => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('searchMgmtDateRange', 'Date')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('all', 'All'),
                          selected: _from == null && _to == null,
                          onTap: () => setState(() {
                            _from = null;
                            _to = null;
                          }),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('promoDateRangeToday', 'Today'),
                          selected: () {
                            if (_from == null) return false;
                            final now = DateTime.now();
                            final start =
                                DateTime(now.year, now.month, now.day);
                            return _from!.year == start.year &&
                                _from!.month == start.month &&
                                _from!.day == start.day;
                          }(),
                          onTap: () {
                            final now = DateTime.now();
                            setState(() {
                              _from = DateTime(now.year, now.month, now.day);
                              _to = now;
                            });
                          },
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('promoDateRange7Days', 'Last 7 days'),
                          selected: () {
                            if (_from == null) return false;
                            final target =
                                DateTime.now().subtract(const Duration(days: 7));
                            return _from!.year == target.year &&
                                _from!.month == target.month &&
                                _from!.day == target.day;
                          }(),
                          onTap: () {
                            final now = DateTime.now();
                            setState(() {
                              _from = now.subtract(const Duration(days: 7));
                              _to = now;
                            });
                          },
                        ),
                        GiftsFilterChoiceChip(
                          label:
                              l10n.tOr('promoDateRange30Days', 'Last 30 days'),
                          selected: () {
                            if (_from == null) return false;
                            final target = DateTime.now()
                                .subtract(const Duration(days: 30));
                            return _from!.year == target.year &&
                                _from!.month == target.month &&
                                _from!.day == target.day;
                          }(),
                          onTap: () {
                            final now = DateTime.now();
                            setState(() {
                              _from = now.subtract(const Duration(days: 30));
                              _to = now;
                            });
                          },
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('promoDateRangeCustom', 'Custom'),
                          selected: _from != null &&
                              _to != null &&
                              _dateLabel(l10n).contains('–'),
                          onTap: _pickCustomDate,
                        ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('searchMgmtTrending', 'Trending')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('all', 'All'),
                          selected: !_trendingOnly,
                          onTap: () => setState(() => _trendingOnly = false),
                        ),
                        GiftsFilterChoiceChip(
                          label:
                              l10n.tOr('searchMgmtTrendingOnly', 'Trending'),
                          selected: _trendingOnly,
                          onTap: () => setState(() => _trendingOnly = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: _close,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
