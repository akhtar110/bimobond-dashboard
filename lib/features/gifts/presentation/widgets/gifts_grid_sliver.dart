import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gifts_view_type.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_responsive.dart';
import 'edit_gift_dialog.dart';
import 'gifts_page_sliver_states.dart';
import 'gifts_table_view.dart';
import 'selectable_gift_card_wrapper.dart';

class GiftsContentSliver extends StatelessWidget {
  const GiftsContentSliver({super.key});

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
            prev.viewType != curr.viewType ||
            prev.searchQuery != curr.searchQuery ||
            prev.fromDate != curr.fromDate ||
            prev.toDate != curr.toDate ||
            prev.minPriceFilter != curr.minPriceFilter ||
            prev.maxPriceFilter != curr.maxPriceFilter ||
            prev.typeFilter != curr.typeFilter ||
            prev.tagFilter != curr.tagFilter ||
            prev.sizeFilter != curr.sizeFilter ||
            prev.publishedFilter != curr.publishedFilter ||
            prev.currentPage != curr.currentPage;
      },
      builder: (context, state) {
        if (state is! GiftsLoaded) return const SliverToBoxAdapter();

        return state.viewType == GiftsViewType.grid
            ? GiftsSliverGrid(loaded: state)
            : GiftsSliverList(loaded: state);
      },
    );
  }
}

class GiftsGridSliver extends GiftsContentSliver {
  const GiftsGridSliver({
    super.key,
    this.onPreviewGift,
    this.giftIdFilter,
    this.preferGiftIdOrder,
  });

  final void Function(BuildContext context, GiftEntity gift)? onPreviewGift;

  /// When set, only gifts whose ids are in this set are shown (group tab).
  final Set<String>? giftIdFilter;

  /// Optional preferred order for [giftIdFilter] (e.g. group sort order).
  final List<String>? preferGiftIdOrder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GiftsBloc, GiftsState>(
      // Selection is handled per-card via BlocSelector — do not rebuild the
      // whole grid when checkboxes change (that was a major scroll jank source).
      buildWhen: (prev, curr) {
        if (prev is! GiftsLoaded || curr is! GiftsLoaded) {
          return prev.runtimeType != curr.runtimeType;
        }
        return prev.gifts != curr.gifts ||
            prev.selectedTab != curr.selectedTab ||
            prev.selectedSort != curr.selectedSort ||
            prev.viewType != curr.viewType ||
            prev.searchQuery != curr.searchQuery ||
            prev.fromDate != curr.fromDate ||
            prev.toDate != curr.toDate ||
            prev.minPriceFilter != curr.minPriceFilter ||
            prev.maxPriceFilter != curr.maxPriceFilter ||
            prev.typeFilter != curr.typeFilter ||
            prev.tagFilter != curr.tagFilter ||
            prev.sizeFilter != curr.sizeFilter ||
            prev.publishedFilter != curr.publishedFilter ||
            prev.currentPage != curr.currentPage;
      },
      builder: (context, state) {
        if (state is! GiftsLoaded) return const SliverToBoxAdapter();

        return state.viewType == GiftsViewType.grid
            ? GiftsSliverGrid(
                loaded: state,
                onPreviewGift: onPreviewGift,
                giftIdFilter: giftIdFilter,
                preferGiftIdOrder: preferGiftIdOrder,
              )
            : GiftsSliverList(
                loaded: state,
                onPreviewGift: onPreviewGift,
                giftIdFilter: giftIdFilter,
                preferGiftIdOrder: preferGiftIdOrder,
              );
      },
    );
  }
}

/// Filters [GiftsLoaded.displayed] by optional group membership, then pages.
List<GiftEntity> giftsPagedForView(
  GiftsLoaded loaded, {
  required bool infiniteScroll,
  Set<String>? giftIdFilter,
  List<String>? preferGiftIdOrder,
}) {
  var items = loaded.displayed;
  if (giftIdFilter != null) {
    if (preferGiftIdOrder != null && preferGiftIdOrder.isNotEmpty) {
      final byId = {for (final g in items) g.id: g};
      items = [
        for (final id in preferGiftIdOrder)
          if (giftIdFilter.contains(id) && byId.containsKey(id)) byId[id]!,
      ];
    } else {
      items = items.where((g) => giftIdFilter.contains(g.id)).toList();
    }
  }

  if (items.isEmpty) return const [];

  // Catalog is already fully loaded from the API. Infinite-scroll mode shows
  // the full filtered list; SliverGrid/List only build visible children.
  final pageSize = GiftsBloc.pageLimit;
  if (infiniteScroll) {
    return items;
  }

  final start = (loaded.currentPage - 1) * pageSize;
  if (start >= items.length) return const [];
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

int giftsFilteredTotalCount(
  GiftsLoaded loaded, {
  Set<String>? giftIdFilter,
}) {
  if (giftIdFilter == null) return loaded.giftsTotalCount;
  return loaded.displayed.where((g) => giftIdFilter.contains(g.id)).length;
}

class GiftsSliverGrid extends StatelessWidget {
  const GiftsSliverGrid({
    super.key,
    required this.loaded,
    this.onPreviewGift,
    this.giftIdFilter,
    this.preferGiftIdOrder,
  });
  final GiftsLoaded loaded;
  final void Function(BuildContext context, GiftEntity gift)? onPreviewGift;
  final Set<String>? giftIdFilter;
  final List<String>? preferGiftIdOrder;

  double _calculateChildAspectRatio(double itemWidth) {
    if (itemWidth < 170) return 0.76;
    if (itemWidth < 210) return 0.82;
    if (itemWidth < 260) return 0.86;
    return 0.88;
  }

  @override
  Widget build(BuildContext context) {
    // Use GiftsViewportWidth (stable during scroll) — NOT SliverLayoutBuilder,
    // which rebuilds every scroll frame via changing SliverConstraints.scrollOffset.
    final crossAxisExtent = GiftsViewportWidth.of(context);
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(crossAxisExtent));
    final gifts = giftsPagedForView(
      loaded,
      infiniteScroll: metrics.useInfiniteScroll,
      giftIdFilter: giftIdFilter,
      preferGiftIdOrder: preferGiftIdOrder,
    );

    if (gifts.isEmpty) {
      return const GiftsSliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    final columns = giftsGridColumnCount(crossAxisExtent);
    final gap = metrics.gridGap;
    final pad = metrics.pageHorizontalPadding;
    final availableWidth = crossAxisExtent - (pad * 2);
    final itemWidth = (availableWidth - (gap * (columns - 1))) / columns;
    final childAspectRatio = _calculateChildAspectRatio(itemWidth);
    final compact = itemWidth < 170;
    final dense = itemWidth < 210;
    final cacheWidth = (itemWidth * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(80, 480);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, metrics.gridTopPadding, pad, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final gift = gifts[index];
            return RepaintBoundary(
              child: SelectableGiftCard(
                key: ValueKey(gift.id),
                gift: gift,
                compact: compact,
                dense: dense,
                cacheWidth: cacheWidth,
                onSelectionChanged: (selected) => toggleGiftSelection(
                  context,
                  gift.id,
                  selected ?? false,
                ),
                onEdit: () => showEditGiftDialog(context, gift),
                onPreview: onPreviewGift == null
                    ? null
                    : () => onPreviewGift!(context, gift),
                onDelete: () => confirmDeleteGift(
                  context,
                  gift.id,
                  gift.name,
                ),
              ),
            );
          },
          childCount: gifts.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

class GiftsSliverList extends StatelessWidget {
  const GiftsSliverList({
    super.key,
    required this.loaded,
    this.onPreviewGift,
    this.giftIdFilter,
    this.preferGiftIdOrder,
  });
  final GiftsLoaded loaded;
  final void Function(BuildContext context, GiftEntity gift)? onPreviewGift;
  final Set<String>? giftIdFilter;
  final List<String>? preferGiftIdOrder;

  @override
  Widget build(BuildContext context) {
    final crossAxisExtent = GiftsViewportWidth.of(context);
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(crossAxisExtent));
    final gifts = giftsPagedForView(
      loaded,
      infiniteScroll: metrics.useInfiniteScroll,
      giftIdFilter: giftIdFilter,
      preferGiftIdOrder: preferGiftIdOrder,
    );

    if (gifts.isEmpty) {
      return const GiftsSliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pad = giftsPageHorizontalPadding(crossAxisExtent);
    final density = giftsTableDensityForWidth(crossAxisExtent);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: GiftsTableHeaderDelegate(
              l10n: l10n,
              scheme: scheme,
              density: density,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gift = gifts[index];
                return RepaintBoundary(
                  child: ColoredBox(
                    key: ValueKey(gift.id),
                    color: scheme.surface,
                    child: _SelectableTableRow(
                      gift: gift,
                      density: density,
                      onPreviewGift: onPreviewGift,
                    ),
                  ),
                );
              },
              childCount: gifts.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTableRow extends StatelessWidget {
  const _SelectableTableRow({
    required this.gift,
    required this.density,
    this.onPreviewGift,
  });

  final GiftEntity gift;
  final GiftsTableDensity density;
  final void Function(BuildContext context, GiftEntity gift)? onPreviewGift;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GiftsBloc, GiftsState, bool>(
      selector: (state) =>
          state is GiftsLoaded && state.selectedGiftIds.contains(gift.id),
      builder: (context, isSelected) {
        return GiftsTableRow(
          gift: gift,
          density: density,
          isSelected: isSelected,
          onSelectionChanged: (selected) => toggleGiftSelection(
            context,
            gift.id,
            selected ?? false,
          ),
          onEdit: () => showEditGiftDialog(context, gift),
          onPreview: onPreviewGift == null
              ? null
              : () => onPreviewGift!(context, gift),
          onDelete: () => confirmDeleteGift(
            context,
            gift.id,
            gift.name,
          ),
        );
      },
    );
  }
}

void confirmDeleteGift(BuildContext context, String id, String name) {
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
