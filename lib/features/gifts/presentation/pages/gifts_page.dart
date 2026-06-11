import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_image_picker.dart';
import '../widgets/gift_card.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Responsive column count for the admin gift grid.
int _columnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 480) return 2;
  return 1;
}

double _hPad(double width) => width < 600 ? 16 : 20;

// ─── Page ─────────────────────────────────────────────────────────────────────

class GiftsPage extends StatefulWidget {
  const GiftsPage({super.key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  @override
  void initState() {
    super.initState();
    context.read<GiftsBloc>().add(LoadAdminGiftsEvent());
  }

  void _showCreateDialog() {
    // Reset any leftover image from a previous session.
    context.read<GiftsBloc>().add(ClearGiftImageEvent());
    showDialog<void>(
      context: context,
      builder: (_) => _CreateGiftDialog(pageContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (ctx, state) {
          if (state is GiftsLoaded) {
            final messenger = ScaffoldMessenger.of(ctx);
            if (state.successMessage != null) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: scheme.primary,
                  behavior: SnackBarBehavior.floating,
                ));
            }
            if (state.errorMessage != null) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: scheme.error,
                  behavior: SnackBarBehavior.floating,
                ));
            }
          }
        },
        builder: (ctx, state) {
          return CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              _SliverHeader(
                theme: theme,
                isLoading: state is GiftsLoading,
                canAdd: state is GiftsLoaded,
                onAdd: _showCreateDialog,
                onRefresh: () =>
                    context.read<GiftsBloc>().add(LoadAdminGiftsEvent()),
              ),

              if (state is GiftsLoaded) ...[
                // ── Sticky filter / search bar ─────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(
                    selectedTab: state.selectedTab,
                    selectedSort: state.selectedSort,
                    searchQuery: state.searchQuery,
                    fromDate: state.fromDate,
                    toDate: state.toDate,
                    minPrice: state.minPriceFilter,
                    maxPrice: state.maxPriceFilter,
                    theme: theme,
                    displayedCount: state.displayed.length,
                    totalCount: state.gifts.length,
                    hasActiveFilters: state.hasActiveFilters,
                  ),
                ),
                // ── Grid ──────────────────────────────────────────────────
                _GiftsGridSliver(),
              ] else if (state is GiftsLoading) ...[
                const _SliverSkeletons(),
              ] else if (state is GiftsError) ...[
                _SliverError(message: state.message),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 56)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sliver Header ────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({
    required this.theme,
    required this.isLoading,
    required this.canAdd,
    required this.onAdd,
    required this.onRefresh,
  });

  final ThemeData theme;
  final bool isLoading;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (_, box) {
          final width = box.maxWidth;
          final pad = _hPad(width);
          final narrow = width < 560;

          final refreshBtn = Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isLoading ? null : onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
          );

          final addBtn = FilledButton.icon(
            onPressed: canAdd ? onAdd : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: narrow ? const SizedBox.shrink() : Text(l10n.t('addGift')),
            style: FilledButton.styleFrom(
              minimumSize: Size(narrow ? 44 : 120, 40),
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 0 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1680),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('gifts'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.35,
                                  color: scheme.onSurface,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.t('giftsSubtitle'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        addBtn,
                        const SizedBox(width: 8),
                        refreshBtn,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                        height: 1, thickness: 1, color: scheme.outlineVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Sticky filter bar (pinned sliver delegate) ───────────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const _FilterBarDelegate({
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

  // tab row(44) + sp(6) + search+date row(46) + sp(6) + sort row(42) + divider(1) + top pad(8)
  static const double _height = 153;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) =>
      old.selectedTab != selectedTab ||
      old.selectedSort != selectedSort ||
      old.searchQuery != searchQuery ||
      old.fromDate != fromDate ||
      old.toDate != toDate ||
      old.minPrice != minPrice ||
      old.maxPrice != maxPrice ||
      old.displayedCount != displayedCount ||
      old.totalCount != totalCount ||
      old.hasActiveFilters != hasActiveFilters;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final scheme = theme.colorScheme;
    final bloc = ctx.read<GiftsBloc>();
    final l10n = ctx.l10n;
    final width = MediaQuery.sizeOf(ctx).width;
    final pad = _hPad(width);

    String tabLabel(GiftFilterTab t) => switch (t) {
          GiftFilterTab.all => l10n.t('giftFilterAll'),
          GiftFilterTab.active => l10n.t('giftFilterActive'),
          GiftFilterTab.inactive => l10n.t('giftFilterInactive'),
        };

    String sortLabel(GiftSortType s) => switch (s) {
          GiftSortType.priceLowToHigh => l10n.t('priceLowToHigh'),
          GiftSortType.priceHighToLow => l10n.t('priceHighToLow'),
          GiftSortType.dateOldToNew => l10n.t('dateOldToNew'),
          GiftSortType.dateNewToOld => l10n.t('dateNewToOld'),
        };

    // ── Date range label ──────────────────────────────────────────────────
    String dateRangeLabel() {
      if (fromDate == null && toDate == null) return l10n.t('dateRange');
      final fmt = (DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      if (fromDate != null && toDate != null) {
        return '${fmt(fromDate!)} – ${fmt(toDate!)}';
      }
      if (fromDate != null) {
        return ctx.tr('dateFrom', {'date': fmt(fromDate!)});
      }
      return ctx.tr('dateUntil', {'date': fmt(toDate!)});
    }

    final hasDateRange = fromDate != null || toDate != null;

    // ── Price range label ─────────────────────────────────────────────────
    String priceRangeLabel() {
      if (minPrice == null && maxPrice == null) return l10n.t('priceRange');
      String fmt(double v) => v.truncateToDouble() == v
          ? '\$${v.toInt()}'
          : '\$${v.toStringAsFixed(2)}';
      if (minPrice != null && maxPrice != null) {
        return '${fmt(minPrice!)} – ${fmt(maxPrice!)}';
      }
      if (minPrice != null) return '${fmt(minPrice!)}+';
      return ctx.tr('priceUpTo', {'amount': fmt(maxPrice!)});
    }

    final hasPriceRange = minPrice != null || maxPrice != null;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Row 1: tab chips + count ───────────────────────────────
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final tab in GiftFilterTab.values)
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: tab != GiftFilterTab.inactive ? 8 : 0,
                                  ),
                                  child: _TabChip(
                                    label: tabLabel(tab),
                                    selected: selectedTab == tab,
                                    theme: theme,
                                    onTap: () =>
                                        bloc.add(ChangeGiftTabFilterEvent(tab)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        ctx.tr('showingResultsCount', {
                          'shown': '$displayedCount',
                          'total': '$totalCount',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Row 2: search + price range + date range picker ───────
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        flex: 3,
                        child: _SearchField(
                          searchQuery: searchQuery,
                          onChanged: (q) =>
                              bloc.add(SearchGiftsEvent(q)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Price range picker button
                      Expanded(
                        flex: 2,
                        child: _DateRangeButton(
                          icon: Icons.attach_money_rounded,
                          label: priceRangeLabel(),
                          hasRange: hasPriceRange,
                          theme: theme,
                          onTap: () {
                            showDialog<void>(
                              context: ctx,
                              builder: (dialogCtx) => _PriceRangeDialog(
                                theme: theme,
                                initialMin: minPrice,
                                initialMax: maxPrice,
                              ),
                            );
                          },
                          onClear: hasPriceRange
                              ? () => bloc.add(UpdatePriceRangeFilterEvent(
                                    minPrice: null,
                                    maxPrice: null,
                                  ))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Date range picker button
                      Expanded(
                        flex: 2,
                        child: _DateRangeButton(
                          label: dateRangeLabel(),
                          hasRange: hasDateRange,
                          theme: theme,
                          onTap: () async {
                            final result = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: hasDateRange
                                  ? DateTimeRange(
                                      start: fromDate ?? toDate!,
                                      end: toDate ?? fromDate!,
                                    )
                                  : null,
                              builder: (ctx, child) => Theme(
                                data: theme,
                                child: child!,
                              ),
                            );
                            if (result != null) {
                              bloc.add(SetDateRangeFilterEvent(
                                fromDate: result.start,
                                toDate: result.end,
                              ));
                            }
                          },
                          onClear: hasDateRange
                              ? () => bloc.add(SetDateRangeFilterEvent(
                                    fromDate: null,
                                    toDate: null,
                                  ))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Row 3: sort dropdowns ─────────────────────────────────
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SortDropdown(
                          key: ValueKey('sort_${selectedSort.name}'),
                          label: l10n.t('sortByPrice'),
                          value: selectedSort == GiftSortType.priceHighToLow
                              ? GiftSortType.priceHighToLow
                              : GiftSortType.priceLowToHigh,
                          items: const [
                            GiftSortType.priceLowToHigh,
                            GiftSortType.priceHighToLow,
                          ],
                          itemLabel: sortLabel,
                          onChanged: (v) {
                            if (v != null) bloc.add(ChangeGiftSortEvent(v));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SortDropdown(
                          key: ValueKey('sort2_${selectedSort.name}'),
                          label: l10n.t('sortByDate'),
                          value: selectedSort == GiftSortType.dateOldToNew
                              ? GiftSortType.dateOldToNew
                              : GiftSortType.dateNewToOld,
                          items: const [
                            GiftSortType.dateNewToOld,
                            GiftSortType.dateOldToNew,
                          ],
                          itemLabel: sortLabel,
                          onChanged: (v) {
                            if (v != null) bloc.add(ChangeGiftSortEvent(v));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search field (stateful so controller survives BLoC rebuilds) ─────────────

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.searchQuery,
    required this.onChanged,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(_SearchField old) {
    super.didUpdateWidget(old);
    // Sync externally-cleared state (e.g. refresh) without clobbering user input.
    if (widget.searchQuery != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: TextStyle(fontSize: 13, color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: l10n.t('searchGifts'),
        hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            : null,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Date range picker button ─────────────────────────────────────────────────

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.label,
    required this.hasRange,
    required this.theme,
    required this.onTap,
    this.icon = Icons.date_range_rounded,
    this.onClear,
  });

  final String label;
  final bool hasRange;
  final ThemeData theme;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final borderColor =
        hasRange ? scheme.primary : scheme.outlineVariant;
    final bgColor = hasRange
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLow;
    final textColor =
        hasRange ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, size: 14, color: textColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: context.l10n.t('clear'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Price range picker dialog ────────────────────────────────────────────────

class _PriceRangeDialog extends StatefulWidget {
  const _PriceRangeDialog({
    required this.theme,
    this.initialMin,
    this.initialMax,
  });

  final ThemeData theme;
  final double? initialMin;
  final double? initialMax;

  @override
  State<_PriceRangeDialog> createState() => _PriceRangeDialogState();
}

class _PriceRangeDialogState extends State<_PriceRangeDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: _format(widget.initialMin));
    _maxCtrl = TextEditingController(text: _format(widget.initialMax));
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _format(double? value) => value == null
      ? ''
      : value.truncateToDouble() == value
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);

  double? _parse(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _apply() {
    var min = _parse(_minCtrl.text);
    var max = _parse(_maxCtrl.text);
    if (min != null && max != null && min > max) {
      final swapped = min;
      min = max;
      max = swapped;
    }
    if (min == null && max == null) {
      Navigator.of(context).pop();
      return;
    }
    context.read<GiftsBloc>().add(
          UpdatePriceRangeFilterEvent(minPrice: min, maxPrice: max),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
    final l10n = context.l10n;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return AlertDialog(
      title: Text(l10n.t('priceRange')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _minCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.t('minPriceLabel'),
                hintText: l10n.t('priceExample'),
                border: border,
                enabledBorder: border,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.t('maxPriceLabel'),
                hintText: l10n.t('priceExampleMax'),
                border: border,
                enabledBorder: border,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _apply,
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

// ─── Tab chip ─────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Sort dropdown ────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final GiftSortType value;
  final List<GiftSortType> items;
  final String Function(GiftSortType) itemLabel;
  final ValueChanged<GiftSortType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<GiftSortType>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(itemLabel(s), overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

/// Rebuilds when any filter/sort input affecting [GiftsLoaded.displayed] changes.
class _GiftsGridSliver extends StatelessWidget {
  const _GiftsGridSliver();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GiftsBloc, GiftsState>(
      buildWhen: (prev, curr) {
        if (prev is! GiftsLoaded || curr is! GiftsLoaded) {
          return prev.runtimeType != curr.runtimeType;
        }
        return prev.gifts != curr.gifts ||
            prev.selectedTab != curr.selectedTab ||
            prev.selectedSort != curr.selectedSort ||
            prev.searchQuery != curr.searchQuery ||
            prev.fromDate != curr.fromDate ||
            prev.toDate != curr.toDate ||
            prev.minPriceFilter != curr.minPriceFilter ||
            prev.maxPriceFilter != curr.maxPriceFilter;
      },
      builder: (context, state) {
        if (state is! GiftsLoaded) return const SliverToBoxAdapter();
        return _SliverGrid(
          key: ValueKey(
            'gifts-grid-${state.selectedTab.name}-'
            '${state.searchQuery}-'
            '${state.fromDate?.millisecondsSinceEpoch}-'
            '${state.toDate?.millisecondsSinceEpoch}-'
            '${state.minPriceFilter}-'
            '${state.maxPriceFilter}-'
            '${state.selectedSort.name}-'
            '${state.displayed.length}',
          ),
          loaded: state,
        );
      },
    );
  }
}

class _SliverGrid extends StatelessWidget {
  const _SliverGrid({super.key, required this.loaded});
  final GiftsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final gifts = loaded.displayed;

    if (gifts.isEmpty) {
      return const _SliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.crossAxisExtent);
        final rowCount = (gifts.length / columns).ceil();
        const gap = 12.0;
        final pad = _hPad(constraints.crossAxisExtent);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final start = rowIndex * columns;
                final end = (start + columns).clamp(0, gifts.length);
                final row = gifts.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? gap : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: i < row.length
                                ? GiftCard(
                                    gift: row[i],
                                    onEdit: () => _showEditDialog(
                                      context,
                                      row[i],
                                    ),
                                    onDelete: () => _confirmDelete(
                                      context,
                                      row[i].id,
                                      row[i].name,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, GiftEntity gift) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditGiftDialog(pageContext: context, gift: gift),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('deleteGiftTitle')),
        content: Text(context.tr('deleteGiftMessage', {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GiftsBloc>().add(DeleteGiftEvent(id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}

// ─── Create dialog ────────────────────────────────────────────────────────────

class _CreateGiftDialog extends StatefulWidget {
  const _CreateGiftDialog({required this.pageContext});
  final BuildContext pageContext;

  @override
  State<_CreateGiftDialog> createState() => _CreateGiftDialogState();
}

class _CreateGiftDialogState extends State<_CreateGiftDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _imageError;
  DateTime? _publishedAt;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickGiftImage();
    if (!mounted || picked == null) return;
    widget.pageContext.read<GiftsBloc>().add(
          SetGiftImageEvent(bytes: picked.bytes, name: picked.name),
        );
    setState(() => _imageError = null);
  }

  Future<void> _pickPublishedAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final initialTime = TimeOfDay.fromDateTime(_publishedAt ?? now);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;

    setState(() {
      if (time != null) {
        _publishedAt =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      } else {
        _publishedAt = date;
      }
    });
  }

  void _submit(GiftsLoaded state) {
    if (state.pendingImageBytes == null) {
      setState(() => _imageError = context.l10n.t('pleaseSelectImage'));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(
          CreateGiftEvent(
            CreateGiftData(
              name: _nameCtrl.text.trim(),
              imageBytes: state.pendingImageBytes!,
              imageName: state.pendingImageName ?? 'gift.jpg',
              priceUsd: double.parse(_priceCtrl.text.trim()),
              publishedAt: _publishedAt,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;

    return BlocBuilder<GiftsBloc, GiftsState>(
      bloc: widget.pageContext.read<GiftsBloc>(),
      buildWhen: (p, c) =>
          c is GiftsLoaded &&
          (p is! GiftsLoaded ||
              p.pendingImageBytes != c.pendingImageBytes ||
              p.isActioning != c.isActioning),
      builder: (_, state) {
        if (state is! GiftsLoaded) return const SizedBox.shrink();

        final hasImage = state.pendingImageBytes != null;
        final canCreate = hasImage && !state.isActioning;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenW < 560 ? 16 : 24,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.t('createNewGift')),
          content: SizedBox(
            width: dialogW,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.t('giftNameLabel'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => v?.trim().isEmpty == true
                          ? l10n.t('requiredField')
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Image picker button
                    OutlinedButton.icon(
                      onPressed: state.isActioning ? null : _pickImage,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: Text(
                        hasImage
                            ? l10n.t('changeImage')
                            : l10n.t('uploadImageRequired'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Image error
                    if (_imageError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _imageError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    // Preview
                    if (hasImage) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.memory(
                            state.pendingImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.pendingImageName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Published At
                    _PublishedAtPicker(
                      value: _publishedAt,
                      onTap: state.isActioning ? null : _pickPublishedAt,
                      onClear: _publishedAt != null
                          ? () => setState(() => _publishedAt = null)
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Price
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.t('giftPriceLabel'),
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v?.trim().isEmpty == true) {
                          return l10n.t('requiredField');
                        }
                        if (double.tryParse(v!.trim()) == null) {
                          return l10n.t('requiredField');
                        }
                        return null;
                      },
                    ),

                    // Uploading indicator
                    if (state.isActioning) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.t('uploadingCreatingGift')),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: canCreate ? () => _submit(state) : null,
              child: Text(l10n.t('createGift')),
            ),
          ],
        );
      },
    );
  }
}

// ─── Edit dialog ─────────────────────────────────────────────────────────────

class _EditGiftDialog extends StatefulWidget {
  const _EditGiftDialog({required this.pageContext, required this.gift});

  final BuildContext pageContext;
  final GiftEntity gift;

  @override
  State<_EditGiftDialog> createState() => _EditGiftDialogState();
}

class _EditGiftDialogState extends State<_EditGiftDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();

  Uint8List? _newImageBytes;
  String? _newImageName;
  DateTime? _publishedAt;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.gift.name);
    _priceCtrl = TextEditingController(
        text: widget.gift.priceUsd.toStringAsFixed(2));
    _publishedAt = widget.gift.publishedAt;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickGiftImage();
    if (!mounted || picked == null) return;
    setState(() {
      _newImageBytes = picked.bytes;
      _newImageName = picked.name;
    });
  }

  Future<void> _pickPublishedAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final initialTime = TimeOfDay.fromDateTime(_publishedAt ?? now);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;
    setState(() {
      _publishedAt = time != null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          : date;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(UpdateGiftEvent(
          widget.gift.id,
          UpdateGiftData(
            name: _nameCtrl.text.trim().isEmpty
                ? null
                : _nameCtrl.text.trim(),
            priceUsd: double.tryParse(_priceCtrl.text.trim()),
            publishedAt: _publishedAt,
            imageBytes: _newImageBytes,
            imageName: _newImageName,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final hasNewImage = _newImageBytes != null;

    return BlocListener<GiftsBloc, GiftsState>(
      bloc: widget.pageContext.read<GiftsBloc>(),
      listenWhen: (p, c) =>
          c is GiftsLoaded &&
          (p is! GiftsLoaded || p.isActioning != c.isActioning),
      listener: (_, state) {
        if (state is GiftsLoaded && !state.isActioning) {
          if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
        }
      },
      child: BlocBuilder<GiftsBloc, GiftsState>(
        bloc: widget.pageContext.read<GiftsBloc>(),
        buildWhen: (p, c) =>
            c is GiftsLoaded &&
            (p is! GiftsLoaded || p.isActioning != c.isActioning),
        builder: (_, state) {
          final isActioning =
              state is GiftsLoaded && state.isActioning;

          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenW < 560 ? 16 : 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.t('editGift')),
            content: SizedBox(
              width: dialogW,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Gift Name ────────────────────────────────────
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.t('giftNameLabel'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => v?.trim().isEmpty == true
                            ? l10n.t('requiredField')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Image section ────────────────────────────────
                      OutlinedButton.icon(
                        onPressed: isActioning ? null : _pickImage,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(
                          hasNewImage
                              ? l10n.t('changeImage')
                              : l10n.t('uploadNewImage'),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preview: new bytes OR existing URL
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: hasNewImage
                              ? Image.memory(
                                  _newImageBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                )
                              : (widget.gift.thumbnailUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.gift.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          _imagePlaceholder(),
                                      errorWidget: (_, __, ___) =>
                                          _imagePlaceholder(),
                                    )
                                  : _imagePlaceholder()),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasNewImage
                            ? _newImageName ?? ''
                            : l10n.t('currentImageHint'),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 14),

                      // ── Price ────────────────────────────────────────
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.t('giftPriceLabel'),
                          prefixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) {
                          if (v?.trim().isEmpty == true) {
                            return l10n.t('requiredField');
                          }
                          if (double.tryParse(v!.trim()) == null) {
                            return l10n.t('requiredField');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Published At ─────────────────────────────────
                      _PublishedAtPicker(
                        value: _publishedAt,
                        onTap: isActioning ? null : _pickPublishedAt,
                        onClear: _publishedAt != null
                            ? () => setState(() => _publishedAt = null)
                            : null,
                      ),

                      // ── Uploading indicator ──────────────────────────
                      if (isActioning) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.t('savingChanges')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.t('cancel')),
              ),
              FilledButton(
                onPressed: isActioning ? null : _submit,
                child: Text(l10n.t('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.card_giftcard_rounded,
            size: 40, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

// ─── Published-at picker widget (used in both create & edit dialogs) ──────────

class _PublishedAtPicker extends StatelessWidget {
  const _PublishedAtPicker({
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasValue = value != null;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm', locale);

    final borderColor = hasValue ? scheme.primary : scheme.outlineVariant;
    final bgColor = hasValue
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLow;
    final textColor =
        hasValue ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.t('publishedAt'),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hasValue
                        ? dateFmt.format(value!.toLocal())
                        : l10n.t('defaultsToNow'),
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 16, color: textColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _SliverSkeletons extends StatelessWidget {
  const _SliverSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (ctx, constraints) {
        final columns = _columnCount(constraints.crossAxisExtent);
        const gap = 12.0;
        const rows = 2;
        final pad = _hPad(constraints.crossAxisExtent);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, rowIndex) => Padding(
                padding:
                    EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < columns; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        const Expanded(child: GiftCardSkeleton()),
                      ],
                    ],
                  ),
                ),
              ),
              childCount: rows,
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _SliverEmptyState extends StatelessWidget {
  const _SliverEmptyState({required this.icon, required this.messageKey});
  final IconData icon;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: scheme.onSurfaceVariant),
              const SizedBox(height: 14),
              Text(
                l10n.t(messageKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverError extends StatelessWidget {
  const _SliverError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: scheme.error),
              const SizedBox(height: 14),
              Text(
                l10n.t('failedToLoadGifts'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<GiftsBloc>().add(LoadAdminGiftsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.t('retry')),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
