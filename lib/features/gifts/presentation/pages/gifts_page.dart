import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FC),
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (ctx, state) {
          if (state is GiftsLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ));
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red.shade700,
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
                isDark: isDark,
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
                    isDark: isDark,
                    theme: theme,
                    displayedCount: state.displayed.length,
                    hasActiveFilters: state.hasActiveFilters,
                  ),
                ),
                // ── Grid ──────────────────────────────────────────────────
                _SliverGrid(loaded: state),
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
    required this.isDark,
    required this.isLoading,
    required this.canAdd,
    required this.onAdd,
    required this.onRefresh,
  });

  final ThemeData theme;
  final bool isDark;
  final bool isLoading;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (_, box) {
          final width = box.maxWidth;
          final pad = _hPad(width);
          final narrow = width < 560;

          final refreshBtn = Material(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
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
                            color: isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF4B5563),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF4B5563),
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
                                  color: titleColor,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage virtual gift catalog for auctions',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtitleColor,
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
                    Divider(height: 1, thickness: 1, color: dividerColor),
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
    required this.isDark,
    required this.theme,
    required this.displayedCount,
    required this.hasActiveFilters,
  });

  final GiftFilterTab selectedTab;
  final GiftSortType selectedSort;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isDark;
  final ThemeData theme;
  final int displayedCount;
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
      old.isDark != isDark ||
      old.displayedCount != displayedCount ||
      old.hasActiveFilters != hasActiveFilters;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FC);
    final divider = isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);
    final metaColor = isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final bloc = ctx.read<GiftsBloc>();
    final l10n = ctx.l10n;
    final width = MediaQuery.sizeOf(ctx).width;
    final pad = _hPad(width);

    String tabLabel(GiftFilterTab t) => switch (t) {
          GiftFilterTab.all => 'Show All',
          GiftFilterTab.active => 'Active Only',
          GiftFilterTab.inactive => 'Inactive Only',
        };

    String sortLabel(GiftSortType s) => switch (s) {
          GiftSortType.priceLowToHigh => 'Price: Low → High',
          GiftSortType.priceHighToLow => 'Price: High → Low',
          GiftSortType.dateOldToNew => 'Date: Oldest first',
          GiftSortType.dateNewToOld => 'Date: Newest first',
        };

    // ── Date range label ──────────────────────────────────────────────────
    String dateRangeLabel() {
      if (fromDate == null && toDate == null) return 'Date Range';
      final fmt = (DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      if (fromDate != null && toDate != null) {
        return '${fmt(fromDate!)} – ${fmt(toDate!)}';
      }
      if (fromDate != null) return 'From ${fmt(fromDate!)}';
      return 'Until ${fmt(toDate!)}';
    }

    final hasDateRange = fromDate != null || toDate != null;

    return Container(
      color: bg,
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
                                    isDark: isDark,
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
                        '$displayedCount gift${displayedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: metaColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Row 2: search + date range picker ─────────────────────
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        flex: 3,
                        child: _SearchField(
                          isDark: isDark,
                          searchQuery: searchQuery,
                          onChanged: (q) =>
                              bloc.add(SearchGiftsEvent(q)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Date range picker button
                      Expanded(
                        flex: 2,
                        child: _DateRangeButton(
                          label: dateRangeLabel(),
                          hasRange: hasDateRange,
                          isDark: isDark,
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
                          isDark: isDark,
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
                          isDark: isDark,
                          onChanged: (v) {
                            if (v != null) bloc.add(ChangeGiftSortEvent(v));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: divider),
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
    required this.isDark,
    required this.searchQuery,
    required this.onChanged,
  });

  final bool isDark;
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: widget.isDark
            ? const Color(0xFF2E3440)
            : const Color(0xFFE8ECF0),
      ),
    );
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 13,
        color: widget.isDark ? Colors.white : const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: 'Search gifts…',
        hintStyle: TextStyle(
          fontSize: 13,
          color: widget.isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color:
              widget.isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
        ),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: widget.isDark
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
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
        fillColor:
            widget.isDark ? const Color(0xFF1A1F2E) : Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
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
    required this.isDark,
    required this.theme,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool hasRange;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final borderColor = hasRange
        ? primary
        : (isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0));
    final bgColor = hasRange
        ? primary.withValues(alpha: 0.08)
        : (isDark ? const Color(0xFF1A1F2E) : Colors.white);
    final textColor = hasRange
        ? primary
        : (isDark ? Colors.grey.shade300 : const Color(0xFF4B5563));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, size: 16, color: textColor),
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
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 14, color: textColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab chip ─────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1A1F2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : (isDark
                    ? const Color(0xFF2E3440)
                    : const Color(0xFFE8ECF0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? primary
                : (isDark
                    ? Colors.grey.shade300
                    : const Color(0xFF4B5563)),
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
    required this.isDark,
    required this.onChanged,
  });

  final String label;
  final GiftSortType value;
  final List<GiftSortType> items;
  final String Function(GiftSortType) itemLabel;
  final bool isDark;
  final ValueChanged<GiftSortType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GiftSortType>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
          ),
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

class _SliverGrid extends StatelessWidget {
  const _SliverGrid({required this.loaded});
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
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: gift.name);
    final thumbCtrl = TextEditingController(text: gift.thumbnailUrl);
    final animCtrl = TextEditingController(text: gift.animationUrl ?? '');
    final priceCtrl =
        TextEditingController(text: gift.priceUsd.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('editGift')),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Gift Name'),
                const SizedBox(height: 12),
                _field(thumbCtrl, 'Thumbnail URL'),
                const SizedBox(height: 12),
                _field(animCtrl, 'Animation URL (optional)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (USD)',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) =>
                      v?.isNotEmpty == true && double.tryParse(v!.trim()) == null
                          ? l10n.t('requiredField')
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              context.read<GiftsBloc>().add(UpdateGiftEvent(
                    gift.id,
                    UpdateGiftData(
                      name: nameCtrl.text.trim().isEmpty
                          ? null
                          : nameCtrl.text.trim(),
                      thumbnailUrl: thumbCtrl.text.trim().isEmpty
                          ? null
                          : thumbCtrl.text.trim(),
                      animationUrl: animCtrl.text.trim().isEmpty
                          ? null
                          : animCtrl.text.trim(),
                      priceUsd: double.tryParse(priceCtrl.text.trim()),
                    ),
                  ));
            },
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  void _confirmDelete(BuildContext context, String id, String name) {
    final l10n = context.l10n;
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  void _submit(GiftsLoaded state) {
    if (state.pendingImageBytes == null) {
      setState(() => _imageError = 'Please select an image');
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
                        labelText: 'Gift Name *',
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
                        hasImage ? 'Change Image' : 'Upload Image *',
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
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFF1F5F9),
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
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

                    // Price
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price (USD) *',
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
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Uploading image & creating gift…'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 52,
                  color: isDark
                      ? Colors.grey.shade600
                      : const Color(0xFF9CA3AF)),
              const SizedBox(height: 14),
              Text(
                l10n.t(messageKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF6B7280),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red.shade400),
              const SizedBox(height: 14),
              Text(
                l10n.t('failedToLoadGifts'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade500
                          : const Color(0xFF9CA3AF),
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
