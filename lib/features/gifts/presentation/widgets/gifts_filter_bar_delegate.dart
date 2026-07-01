import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_responsive.dart';
import 'gifts_filter_controls.dart';

class GiftsFilterBarDelegate extends SliverPersistentHeaderDelegate {
  const GiftsFilterBarDelegate({
    required this.selectedTab,
    required this.selectedSort,
    required this.searchQuery,
    required this.fromDate,
    required this.toDate,
    required this.minPrice,
    required this.maxPrice,
    required this.theme,
    required this.displayedCount,
    required this.totalCount,
    required this.hasActiveFilters,
    required this.screenWidth,
  });

  final GiftFilterTab selectedTab;
  final GiftSortType selectedSort;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minPrice;
  final double? maxPrice;
  final ThemeData theme;
  final int displayedCount;
  final int totalCount;
  final bool hasActiveFilters;
  final double screenWidth;

  @override
  double get minExtent => giftsFilterBarHeight(screenWidth);
  @override
  double get maxExtent => giftsFilterBarHeight(screenWidth);

  @override
  bool shouldRebuild(covariant GiftsFilterBarDelegate old) =>
      old.selectedTab != selectedTab ||
      old.selectedSort != selectedSort ||
      old.searchQuery != searchQuery ||
      old.fromDate != fromDate ||
      old.toDate != toDate ||
      old.minPrice != minPrice ||
      old.maxPrice != maxPrice ||
      old.displayedCount != displayedCount ||
      old.totalCount != totalCount ||
      old.hasActiveFilters != hasActiveFilters ||
      old.screenWidth != screenWidth ||
      old.theme.brightness != theme.brightness ||
      old.theme.scaffoldBackgroundColor != theme.scaffoldBackgroundColor;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(ctx);
    final scheme = theme.colorScheme;
    final barColor = giftsToolbarBarBackground(scheme);
    final bloc = ctx.read<GiftsBloc>();
    final l10n = ctx.l10n;
    final width = MediaQuery.sizeOf(ctx).width;
    final pad = giftsPageHorizontalPadding(width);
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(width));
    final tabGap = metrics.isMobile ? 6.0 : 8.0;

    String tabLabel(GiftFilterTab t) => switch (t) {
          GiftFilterTab.all => l10n.t('giftFilterAll'),
          GiftFilterTab.active => l10n.t('giftFilterActive'),
          GiftFilterTab.inactive => l10n.t('giftFilterInactive'),
        };

    String sortLabel(GiftSortType s) => switch (s) {
          GiftSortType.priceLowToHigh => l10n.t('priceLowToHigh'),
          GiftSortType.priceHighToLow => l10n.t('priceHighToLow'),
          GiftSortType.dateOldToNew => 'Oldest Gifts',
          GiftSortType.dateNewToOld => 'Newest Gifts',
        };

    return Material(
      color: barColor,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: SizedBox(
        height: maxExtent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1680),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                metrics.filterBarTopPadding,
                pad,
                metrics.filterBarBottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: metrics.tabStripHeight,
                    child: metrics.hideResultsCountInline
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final tab in GiftFilterTab.values)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: tab != GiftFilterTab.inactive
                                          ? tabGap
                                          : 0,
                                    ),
                                    child: GiftsTabChip(
                                      label: tabLabel(tab),
                                      selected: selectedTab == tab,
                                      theme: theme,
                                      compact: true,
                                      onTap: () => bloc.add(
                                        ChangeGiftTabFilterEvent(tab),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final tab in GiftFilterTab.values)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: tab != GiftFilterTab.inactive
                                                ? tabGap
                                                : 0,
                                          ),
                                          child: GiftsTabChip(
                                            label: tabLabel(tab),
                                            selected: selectedTab == tab,
                                            theme: theme,
                                            compact: metrics.isMobile,
                                            onTap: () => bloc.add(
                                              ChangeGiftTabFilterEvent(tab),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: metrics.isMobile ? 8 : 12),
                              Text(
                                ctx.tr('showingResultsCount', {
                                  'shown': '$displayedCount',
                                  'total': '$totalCount',
                                }),
                                style: TextStyle(
                                  fontSize: metrics.isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (metrics.hideResultsCountInline) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    Text(
                      ctx.tr('showingResultsCount', {
                        'shown': '$displayedCount',
                        'total': '$totalCount',
                      }),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  SizedBox(height: metrics.filterGap),
                  _GiftsModernToolbar(
                    width: screenWidth,
                    metrics: metrics,
                    searchQuery: searchQuery,
                    selectedSort: selectedSort,
                    fromDate: fromDate,
                    toDate: toDate,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    theme: theme,
                    onSearchChanged: (q) => bloc.add(SearchGiftsEvent(q)),
                    onSortChanged: (s) => bloc.add(ChangeGiftSortEvent(s)),
                    onPriceRangeChanged: (min, max) => bloc.add(
                      UpdatePriceRangeFilterEvent(minPrice: min, maxPrice: max),
                    ),
                    onDateRangeChanged: (from, to) => bloc.add(
                      SetDateRangeFilterEvent(fromDate: from, toDate: to),
                    ),
                    sortLabel: sortLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftsModernToolbar extends StatelessWidget {
  const _GiftsModernToolbar({
    required this.width,
    required this.metrics,
    required this.searchQuery,
    required this.selectedSort,
    required this.fromDate,
    required this.toDate,
    required this.minPrice,
    required this.maxPrice,
    required this.theme,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onPriceRangeChanged,
    required this.onDateRangeChanged,
    required this.sortLabel,
  });

  final double width;
  final GiftsLayoutMetrics metrics;
  final String searchQuery;
  final GiftSortType selectedSort;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minPrice;
  final double? maxPrice;
  final ThemeData theme;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<GiftSortType> onSortChanged;
  final void Function(double? minPrice, double? maxPrice) onPriceRangeChanged;
  final void Function(DateTime? fromDate, DateTime? toDate) onDateRangeChanged;
  final String Function(GiftSortType) sortLabel;

  bool get _isInlineToolbar => width >= 760;

  @override
  Widget build(BuildContext context) {
    final hasPrice = minPrice != null || maxPrice != null;
    final hasDate = fromDate != null || toDate != null;
    final hasPriceDate = hasPrice || hasDate;

    final controlHeight = metrics.filterControlHeight;
    final gap = metrics.toolbarFilterGap;

    final search = GiftsSearchField(
      searchQuery: searchQuery,
      height: controlHeight,
      compact: metrics.isMobile,
      onChanged: onSearchChanged,
    );

    final filtersBtn = _ToolbarButton(
      label: metrics.isMobile ? 'Filters' : 'Price & Date Filters',
      icon: Icons.tune_rounded,
      isActive: hasPriceDate,
      compact: metrics.isMobile,
      controlHeight: controlHeight,
      borderRadius: metrics.toolbarControlRadius,
      onTap: () => _openPriceDateFilters(context),
    );

    final sortBtn = _SortToolbarButton(
      selectedSort: selectedSort,
      sortLabel: sortLabel,
      compact: metrics.isMobile,
      controlHeight: controlHeight,
      borderRadius: metrics.toolbarControlRadius,
      onChanged: onSortChanged,
    );

    if (_isInlineToolbar) {
      return SizedBox(
        height: controlHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: search),
            SizedBox(width: metrics.isMobile ? 8 : 12),
            SizedBox(
              width: metrics.isMobile ? 180 : 220,
              child: filtersBtn,
            ),
            SizedBox(width: gap),
            SizedBox(
              width: metrics.isMobile ? 120 : 140,
              child: sortBtn,
            ),
          ],
        ),
      );
    }

    if (metrics.useCompactFilterToolbar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          SizedBox(height: gap),
          SizedBox(
            height: controlHeight,
            child: Row(
              children: [
                Expanded(child: filtersBtn),
                SizedBox(width: gap),
                Expanded(child: sortBtn),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        SizedBox(height: gap),
        SizedBox(height: controlHeight, child: filtersBtn),
        SizedBox(height: gap),
        SizedBox(height: controlHeight, child: sortBtn),
      ],
    );
  }

  Future<void> _openPriceDateFilters(BuildContext context) async {
    final isMobile = width < 700;
    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _PriceDateFiltersSheet(
          theme: theme,
          minPrice: minPrice,
          maxPrice: maxPrice,
          fromDate: fromDate,
          toDate: toDate,
          onPriceRangeChanged: onPriceRangeChanged,
          onDateRangeChanged: onDateRangeChanged,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Align(
          alignment: Alignment.topRight,
          child: _PriceDateFiltersCard(
            theme: theme,
            minPrice: minPrice,
            maxPrice: maxPrice,
            fromDate: fromDate,
            toDate: toDate,
            onPriceRangeChanged: onPriceRangeChanged,
            onDateRangeChanged: onDateRangeChanged,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
    this.controlHeight = giftsToolbarControlHeight,
    this.borderRadius = giftsToolbarControlRadius,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool compact;
  final double controlHeight;
  final double borderRadius;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Ink(
            decoration: giftsToolbarControlDecoration(
              scheme,
              isActive: widget.isActive,
              hovered: _hovered,
            ).copyWith(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 14,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: widget.compact ? 16 : 18,
                    color: fg,
                  ),
                  SizedBox(width: widget.compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: fg,
                    size: widget.compact ? 16 : 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortToolbarButton extends StatelessWidget {
  const _SortToolbarButton({
    required this.selectedSort,
    required this.sortLabel,
    required this.onChanged,
    this.compact = false,
    this.controlHeight = giftsToolbarControlHeight,
    this.borderRadius = giftsToolbarControlRadius,
  });

  final GiftSortType selectedSort;
  final String Function(GiftSortType) sortLabel;
  final ValueChanged<GiftSortType> onChanged;
  final bool compact;
  final double controlHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: controlHeight,
      width: double.infinity,
      child: PopupMenuButton<GiftSortType>(
        onSelected: onChanged,
        tooltip: context.l10n.t('sortByDate'),
        padding: EdgeInsets.zero,
        splashRadius: 20,
        itemBuilder: (ctx) => GiftSortType.values
            .map(
              (s) => PopupMenuItem<GiftSortType>(
                value: s,
                child: Row(
                  children: [
                    Expanded(child: Text(sortLabel(s))),
                    if (s == selectedSort)
                      Icon(Icons.check_rounded, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            )
            .toList(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: scheme.surface,
        child: DecoratedBox(
          decoration: giftsToolbarControlDecoration(scheme).copyWith(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: SizedBox(
            height: controlHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: compact ? 16 : 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                    size: compact ? 16 : 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactDateRangeDialog extends StatefulWidget {
  const _CompactDateRangeDialog({
    required this.initialFrom,
    required this.initialTo,
    required this.theme,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final ThemeData theme;

  @override
  State<_CompactDateRangeDialog> createState() => _CompactDateRangeDialogState();
}

class _CompactDateRangeDialogState extends State<_CompactDateRangeDialog> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _from ?? _to ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _from = picked;
      if (_to != null && _to!.isBefore(_from!)) _to = _from;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _to ?? _from ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _to = picked;
      if (_from != null && _from!.isAfter(_to!)) _from = _to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.t('dateRange')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DatePickRow(label: l10n.t('from'), value: _fmt(_from), onTap: _pickFrom),
            const SizedBox(height: 10),
            _DatePickRow(label: l10n.t('to'), value: _fmt(_to), onTap: _pickTo),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<(DateTime?, DateTime?)>(null),
          child: Text(l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop<(DateTime?, DateTime?)>((null, null)),
          child: Text(l10n.t('clear')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<(DateTime?, DateTime?)>((_from, _to)),
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

class _DatePickRow extends StatelessWidget {
  const _DatePickRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceDateFiltersSheet extends StatelessWidget {
  const _PriceDateFiltersSheet({
    required this.theme,
    required this.minPrice,
    required this.maxPrice,
    required this.fromDate,
    required this.toDate,
    required this.onPriceRangeChanged,
    required this.onDateRangeChanged,
  });

  final ThemeData theme;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? fromDate;
  final DateTime? toDate;
  final void Function(double? minPrice, double? maxPrice) onPriceRangeChanged;
  final void Function(DateTime? fromDate, DateTime? toDate) onDateRangeChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _PriceDatePanelContent(
            theme: theme,
            minPrice: minPrice,
            maxPrice: maxPrice,
            fromDate: fromDate,
            toDate: toDate,
            onPriceRangeChanged: onPriceRangeChanged,
            onDateRangeChanged: onDateRangeChanged,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _PriceDateFiltersCard extends StatelessWidget {
  const _PriceDateFiltersCard({
    required this.theme,
    required this.minPrice,
    required this.maxPrice,
    required this.fromDate,
    required this.toDate,
    required this.onPriceRangeChanged,
    required this.onDateRangeChanged,
    required this.onClose,
  });

  final ThemeData theme;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? fromDate;
  final DateTime? toDate;
  final void Function(double? minPrice, double? maxPrice) onPriceRangeChanged;
  final void Function(DateTime? fromDate, DateTime? toDate) onDateRangeChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 8,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: _PriceDatePanelContent(
            theme: theme,
            minPrice: minPrice,
            maxPrice: maxPrice,
            fromDate: fromDate,
            toDate: toDate,
            onPriceRangeChanged: onPriceRangeChanged,
            onDateRangeChanged: onDateRangeChanged,
            onClose: onClose,
          ),
        ),
      ),
    );
  }
}

class _PriceDatePanelContent extends StatefulWidget {
  const _PriceDatePanelContent({
    required this.theme,
    required this.minPrice,
    required this.maxPrice,
    required this.fromDate,
    required this.toDate,
    required this.onPriceRangeChanged,
    required this.onDateRangeChanged,
    required this.onClose,
  });

  final ThemeData theme;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? fromDate;
  final DateTime? toDate;
  final void Function(double? minPrice, double? maxPrice) onPriceRangeChanged;
  final void Function(DateTime? fromDate, DateTime? toDate) onDateRangeChanged;
  final VoidCallback onClose;

  @override
  State<_PriceDatePanelContent> createState() => _PriceDatePanelContentState();
}

class _PriceDatePanelContentState extends State<_PriceDatePanelContent> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: _fmtPrice(widget.minPrice));
    _maxCtrl = TextEditingController(text: _fmtPrice(widget.maxPrice));
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _fmtPrice(double? v) {
    if (v == null) return '';
    return v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  double? _parsePrice(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _fromDate ?? _toDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) _toDate = _fromDate;
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _fromDate!.isAfter(_toDate!)) _fromDate = _toDate;
    });
  }

  void _applyFilters() {
    var min = _parsePrice(_minCtrl.text);
    var max = _parsePrice(_maxCtrl.text);
    if (min != null && max != null && min > max) {
      final temp = min;
      min = max;
      max = temp;
    }

    DateTime? from = _fromDate;
    DateTime? to = _toDate;
    if (from != null && to != null && from.isAfter(to)) {
      final temp = from;
      from = to;
      to = temp;
    }

    widget.onPriceRangeChanged(min, max);
    widget.onDateRangeChanged(from, to);
    widget.onClose();
  }

  void _resetFilters() {
    _minCtrl.clear();
    _maxCtrl.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    widget.onPriceRangeChanged(null, null);
    widget.onDateRangeChanged(null, null);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = widget.theme.colorScheme;
    final outline = giftsToolbarInputBorder(scheme);
    final focused = giftsToolbarInputBorder(
      scheme,
      color: scheme.primary,
      width: 1.5,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, size: 18, color: widget.theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Price & Date Filters',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t('minPriceLabel'),
                  hintText: l10n.t('priceExample'),
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: focused,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _maxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t('maxPriceLabel'),
                  hintText: l10n.t('priceExampleMax'),
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: focused,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _pickFromDate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(giftsToolbarControlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(giftsToolbarControlRadius),
                  ),
                  side: BorderSide(color: giftsToolbarBorderColor(scheme)),
                ),
                child: Text('From: ${_fmtDate(_fromDate)}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _pickToDate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(giftsToolbarControlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(giftsToolbarControlRadius),
                  ),
                  side: BorderSide(color: giftsToolbarBorderColor(scheme)),
                ),
                child: Text('To: ${_fmtDate(_toDate)}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: giftsToolbarBorderColor(scheme)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt_rounded, size: 16),
                label: const Text('Filter'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
