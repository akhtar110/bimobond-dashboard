import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
import '../bloc/gifts_bloc.dart';
import 'gifts_active_filters.dart';
import 'gifts_filter_chip.dart';
import 'gifts_filter_controls.dart';
import 'gifts_filter_footer.dart';
import 'gifts_filter_header.dart';
import 'gifts_filter_models.dart';
import 'gifts_filter_section.dart';

/// Opens the adaptive Pinterest-style filter panel.
Future<void> showGiftsFilterPopup({
  required BuildContext context,
  required GiftsLoaded loaded,
  required Rect anchorRect,
  ValueChanged<GiftFilterTab>? onStatusFilterSelected,
}) {
  // Dialogs/sheets sit above the page route — re-provide the page bloc.
  final giftsBloc = context.read<GiftsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<GiftsBloc>.value(
        value: giftsBloc,
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
          GiftsFilterPopup(
            loaded: loaded,
            giftsBloc: giftsBloc,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            onStatusFilterSelected: onStatusFilterSelected,
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
            GiftsFilterPopup(
              loaded: loaded,
              giftsBloc: giftsBloc,
              width: 400,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
              onStatusFilterSelected: onStatusFilterSelected,
            ),
          ),
        ),
      ),
    );
  }

  final panelWidth = 380.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.72;
  if (top + 360 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 360.0);
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
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  GiftsFilterPopup(
                    loaded: loaded,
                    giftsBloc: giftsBloc,
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                    onStatusFilterSelected: onStatusFilterSelected,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Filter panel body with draft editing + Apply via existing BLoC events.
class GiftsFilterPopup extends StatefulWidget {
  const GiftsFilterPopup({
    super.key,
    required this.loaded,
    required this.giftsBloc,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.onStatusFilterSelected,
  });

  final GiftsLoaded loaded;
  final GiftsBloc giftsBloc;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final ValueChanged<GiftFilterTab>? onStatusFilterSelected;

  @override
  State<GiftsFilterPopup> createState() => _GiftsFilterPopupState();
}

class _GiftsFilterPopupState extends State<GiftsFilterPopup> {
  late GiftsFilterDraft _draft;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _draft = GiftsFilterDraft.fromLoaded(widget.loaded);
    _minCtrl = TextEditingController(
      text: giftsFilterFormatPrice(_draft.minPrice),
    );
    _maxCtrl = TextEditingController(
      text: giftsFilterFormatPrice(_draft.maxPrice),
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _syncPriceFromFields() {
    _draft.minPrice = _parsePrice(_minCtrl.text);
    _draft.maxPrice = _parsePrice(_maxCtrl.text);
  }

  double? _parsePrice(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _resetDraft() {
    setState(() {
      _draft.reset();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
    _apply(close: false);
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _apply({bool close = false}) {
    _syncPriceFromFields();

    var min = _draft.minPrice;
    var max = _draft.maxPrice;
    if (min != null && max != null && min > max) {
      final temp = min;
      min = max;
      max = temp;
    }

    var from = _draft.fromDate;
    var to = _draft.toDate;
    if (from != null && to != null && from.isAfter(to)) {
      final temp = from;
      from = to;
      to = temp;
    }

    final bloc = widget.giftsBloc;
    widget.onStatusFilterSelected?.call(_draft.status);
    bloc.add(
      ApplyGiftsFiltersEvent(
        status: _draft.status,
        sort: _draft.sort,
        setTypeFilter: true,
        typeFilter: _draft.typeFilter,
        tagFilter: _draft.tagFilter,
        setSizeFilter: true,
        sizeFilter: _draft.sizeFilter,
        publishedFilter: _draft.publishedFilter,
        setPriceRange: true,
        minPrice: min,
        maxPrice: max,
        setDateRange: true,
        fromDate: from,
        toDate: to,
      ),
    );
    if (close) {
      _close();
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _draft.fromDate ?? _draft.toDate ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draft.fromDate = picked;
      if (_draft.toDate != null && _draft.toDate!.isBefore(picked)) {
        _draft.toDate = picked;
      }
    });
    _apply(close: false);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _draft.toDate ?? _draft.fromDate ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draft.toDate = picked;
      if (_draft.fromDate != null && _draft.fromDate!.isAfter(picked)) {
        _draft.fromDate = picked;
      }
    });
    _apply(close: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    final activeItems = giftsActiveFilterItems(
      _draft,
      l10n,
      onChanged: () {
        _minCtrl.text = giftsFilterFormatPrice(_draft.minPrice);
        _maxCtrl.text = giftsFilterFormatPrice(_draft.maxPrice);
        setState(() {});
        _apply(close: false);
      },
    );

    final panel = Material(
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
            GiftsFilterHeader(
              onResetAll: _resetDraft,
              onClose: _close,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  GiftsFilterSection(
                    title: l10n.tOr('status', 'Status').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final tab in GiftFilterTab.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterStatusLabel(l10n, tab),
                            selected: _draft.status == tab,
                            onTap: () {
                              setState(() => _draft.status = tab);
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title:
                        l10n.tOr('giftFilterSorting', 'Sorting').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final sort in GiftSortType.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterSortLabel(l10n, sort),
                            selected: _draft.sort == sort,
                            onTap: () {
                              setState(() => _draft.sort = sort);
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('giftFilterType', 'Type').toUpperCase(),
                    initiallyExpanded: false,
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: giftsFilterTypeLabel(l10n, null),
                          selected: _draft.typeFilter == null,
                          onTap: () {
                            setState(() => _draft.typeFilter = null);
                            _apply(close: false);
                          },
                        ),
                        for (final type in GiftType.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterTypeLabel(l10n, type),
                            selected: _draft.typeFilter == type,
                            onTap: () {
                              setState(() => _draft.typeFilter = type);
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('giftFilterTag', 'Tag').toUpperCase(),
                    initiallyExpanded: false,
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final tag in GiftTagFilter.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterTagLabel(l10n, tag),
                            selected: _draft.tagFilter == tag,
                            onTap: () {
                              setState(() => _draft.tagFilter = tag);
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('giftFilterSize', 'Size').toUpperCase(),
                    initiallyExpanded: false,
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: giftsFilterSizeLabel(l10n, null),
                          selected: _draft.sizeFilter == null,
                          onTap: () {
                            setState(() => _draft.sizeFilter = null);
                            _apply(close: false);
                          },
                        ),
                        for (final size in GiftSize.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterSizeLabel(l10n, size),
                            selected: _draft.sizeFilter == size,
                            onTap: () {
                              setState(() => _draft.sizeFilter = size);
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('giftFilterPublished', 'Published')
                        .toUpperCase(),
                    initiallyExpanded: false,
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final published in GiftPublishedFilter.values)
                          GiftsFilterChoiceChip(
                            label: giftsFilterPublishedLabel(l10n, published),
                            selected: _draft.publishedFilter == published,
                            onTap: () {
                              setState(
                                () => _draft.publishedFilter = published,
                              );
                              _apply(close: false);
                            },
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('giftFilterPrice', 'Price').toUpperCase(),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (_) {
                              _syncPriceFromFields();
                              setState(() {});
                              _apply(close: false);
                            },
                            decoration: InputDecoration(
                              labelText: l10n.t('minPriceLabel'),
                              hintText: l10n.tOr('priceExample', '0'),
                              border: giftsToolbarInputBorder(scheme),
                              enabledBorder: giftsToolbarInputBorder(scheme),
                              focusedBorder: giftsToolbarInputBorder(
                                scheme,
                                color: scheme.primary,
                                width: 1.5,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (_) {
                              _syncPriceFromFields();
                              setState(() {});
                              _apply(close: false);
                            },
                            decoration: InputDecoration(
                              labelText: l10n.t('maxPriceLabel'),
                              hintText: l10n.tOr('priceExampleMax', '1000'),
                              border: giftsToolbarInputBorder(scheme),
                              enabledBorder: giftsToolbarInputBorder(scheme),
                              focusedBorder: giftsToolbarInputBorder(
                                scheme,
                                color: scheme.primary,
                                width: 1.5,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('giftFilterDate', 'Date').toUpperCase(),
                    initiallyExpanded: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickFrom,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _draft.fromDate == null
                                  ? l10n.tOr('giftFilterFrom', 'From')
                                  : '${l10n.tOr('giftFilterFrom', 'From')}: ${giftsFilterFormatDate(_draft.fromDate)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTo,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _draft.toDate == null
                                  ? l10n.tOr('giftFilterTo', 'To')
                                  : '${l10n.tOr('giftFilterTo', 'To')}: ${giftsFilterFormatDate(_draft.toDate)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GiftsActiveFilters(items: activeItems),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _resetDraft,
              onCancel: _close,
            ),
          ],
        ),
      ),
    );

    return panel;
  }
}
