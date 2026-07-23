import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';

/// Counts applied catalog filters (excludes search — search stays outside).
int giftsAppliedFilterCount(GiftsLoaded loaded) {
  var count = 0;
  if (loaded.selectedTab != GiftFilterTab.all) count++;
  if (loaded.selectedSort != GiftSortType.dateNewToOld) count++;
  if (loaded.minPriceFilter != null) count++;
  if (loaded.maxPriceFilter != null) count++;
  if (loaded.fromDate != null) count++;
  if (loaded.toDate != null) count++;
  return count;
}

/// Mutable draft of filter values edited inside the popup before Apply.
class GiftsFilterDraft {
  GiftsFilterDraft({
    required this.status,
    required this.sort,
    this.minPrice,
    this.maxPrice,
    this.fromDate,
    this.toDate,
  });

  factory GiftsFilterDraft.fromLoaded(GiftsLoaded loaded) {
    return GiftsFilterDraft(
      status: loaded.selectedTab,
      sort: loaded.selectedSort,
      minPrice: loaded.minPriceFilter,
      maxPrice: loaded.maxPriceFilter,
      fromDate: loaded.fromDate,
      toDate: loaded.toDate,
    );
  }

  GiftFilterTab status;
  GiftSortType sort;
  double? minPrice;
  double? maxPrice;
  DateTime? fromDate;
  DateTime? toDate;

  GiftsFilterDraft copy() => GiftsFilterDraft(
        status: status,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        fromDate: fromDate,
        toDate: toDate,
      );

  void reset() {
    status = GiftFilterTab.all;
    sort = GiftSortType.dateNewToOld;
    minPrice = null;
    maxPrice = null;
    fromDate = null;
    toDate = null;
  }

  int get activeCount {
    var count = 0;
    if (status != GiftFilterTab.all) count++;
    if (sort != GiftSortType.dateNewToOld) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    return count;
  }
}

String giftsFilterStatusLabel(AppLocalizations l10n, GiftFilterTab tab) {
  return switch (tab) {
    GiftFilterTab.all => l10n.tOr('giftFilterAllShort', 'All'),
    GiftFilterTab.active => l10n.tOr('giftFilterActiveShort', 'Active'),
    GiftFilterTab.inactive => l10n.tOr('giftFilterInactiveShort', 'Inactive'),
  };
}

String giftsFilterSortLabel(AppLocalizations l10n, GiftSortType sort) {
  return switch (sort) {
    GiftSortType.priceLowToHigh => l10n.t('priceLowToHigh'),
    GiftSortType.priceHighToLow => l10n.t('priceHighToLow'),
    GiftSortType.dateOldToNew => l10n.tOr('oldestGifts', 'Oldest Gifts'),
    GiftSortType.dateNewToOld => l10n.tOr('newestGifts', 'Newest Gifts'),
  };
}

String giftsFilterFormatPrice(double? value) {
  if (value == null) return '';
  return value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String giftsFilterFormatDate(DateTime? date) {
  if (date == null) return '';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

/// Removable summary chip model for the active-filters strip.
class GiftsActiveFilterItem {
  const GiftsActiveFilterItem({
    required this.id,
    required this.label,
    required this.onRemove,
  });

  final String id;
  final String label;
  final VoidCallback onRemove;
}

List<GiftsActiveFilterItem> giftsActiveFilterItems(
  GiftsFilterDraft draft,
  AppLocalizations l10n, {
  required VoidCallback onChanged,
}) {
  final items = <GiftsActiveFilterItem>[];

  if (draft.status != GiftFilterTab.all) {
    items.add(
      GiftsActiveFilterItem(
        id: 'status',
        label: giftsFilterStatusLabel(l10n, draft.status),
        onRemove: () {
          draft.status = GiftFilterTab.all;
          onChanged();
        },
      ),
    );
  }

  if (draft.sort != GiftSortType.dateNewToOld) {
    items.add(
      GiftsActiveFilterItem(
        id: 'sort',
        label: giftsFilterSortLabel(l10n, draft.sort),
        onRemove: () {
          draft.sort = GiftSortType.dateNewToOld;
          onChanged();
        },
      ),
    );
  }

  if (draft.minPrice != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'minPrice',
        label:
            '${l10n.tOr('giftFilterMinPriceChip', 'Min')} ${giftsFilterFormatPrice(draft.minPrice)}',
        onRemove: () {
          draft.minPrice = null;
          onChanged();
        },
      ),
    );
  }

  if (draft.maxPrice != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'maxPrice',
        label:
            '${l10n.tOr('giftFilterMaxPriceChip', 'Max')} ${giftsFilterFormatPrice(draft.maxPrice)}',
        onRemove: () {
          draft.maxPrice = null;
          onChanged();
        },
      ),
    );
  }

  if (draft.fromDate != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'fromDate',
        label:
            '${l10n.tOr('giftFilterFromChip', 'From')} ${giftsFilterFormatDate(draft.fromDate)}',
        onRemove: () {
          draft.fromDate = null;
          onChanged();
        },
      ),
    );
  }

  if (draft.toDate != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'toDate',
        label:
            '${l10n.tOr('giftFilterToChip', 'To')} ${giftsFilterFormatDate(draft.toDate)}',
        onRemove: () {
          draft.toDate = null;
          onChanged();
        },
      ),
    );
  }

  return items;
}
