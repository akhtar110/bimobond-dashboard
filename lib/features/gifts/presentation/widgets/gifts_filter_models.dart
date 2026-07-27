import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
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
  if (loaded.typeFilter != null) count++;
  if (loaded.tagFilter != GiftTagFilter.any) count++;
  if (loaded.sizeFilter != null) count++;
  if (loaded.publishedFilter != GiftPublishedFilter.any) count++;
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
    this.typeFilter,
    this.tagFilter = GiftTagFilter.any,
    this.sizeFilter,
    this.publishedFilter = GiftPublishedFilter.any,
  });

  factory GiftsFilterDraft.fromLoaded(GiftsLoaded loaded) {
    return GiftsFilterDraft(
      status: loaded.selectedTab,
      sort: loaded.selectedSort,
      minPrice: loaded.minPriceFilter,
      maxPrice: loaded.maxPriceFilter,
      fromDate: loaded.fromDate,
      toDate: loaded.toDate,
      typeFilter: loaded.typeFilter,
      tagFilter: loaded.tagFilter,
      sizeFilter: loaded.sizeFilter,
      publishedFilter: loaded.publishedFilter,
    );
  }

  GiftFilterTab status;
  GiftSortType sort;
  double? minPrice;
  double? maxPrice;
  DateTime? fromDate;
  DateTime? toDate;
  GiftType? typeFilter;
  GiftTagFilter tagFilter;
  GiftSize? sizeFilter;
  GiftPublishedFilter publishedFilter;

  GiftsFilterDraft copy() => GiftsFilterDraft(
        status: status,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        fromDate: fromDate,
        toDate: toDate,
        typeFilter: typeFilter,
        tagFilter: tagFilter,
        sizeFilter: sizeFilter,
        publishedFilter: publishedFilter,
      );

  void reset() {
    status = GiftFilterTab.all;
    sort = GiftSortType.dateNewToOld;
    minPrice = null;
    maxPrice = null;
    fromDate = null;
    toDate = null;
    typeFilter = null;
    tagFilter = GiftTagFilter.any;
    sizeFilter = null;
    publishedFilter = GiftPublishedFilter.any;
  }

  int get activeCount {
    var count = 0;
    if (status != GiftFilterTab.all) count++;
    if (sort != GiftSortType.dateNewToOld) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    if (typeFilter != null) count++;
    if (tagFilter != GiftTagFilter.any) count++;
    if (sizeFilter != null) count++;
    if (publishedFilter != GiftPublishedFilter.any) count++;
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
    GiftSortType.sortOrderAsc => l10n.tOr('sortBySortOrder', 'Sort Order'),
    GiftSortType.nameAsc => l10n.tOr('sortByName', 'Name'),
  };
}

String giftsFilterTypeLabel(AppLocalizations l10n, GiftType? type) {
  if (type == null) return l10n.tOr('allTypes', 'All');
  return switch (type) {
    GiftType.image => l10n.tOr('giftTypeImage', 'IMAGE'),
    GiftType.audio => l10n.tOr('giftTypeAudio', 'AUDIO'),
  };
}

String giftsFilterTagLabel(AppLocalizations l10n, GiftTagFilter tag) {
  return switch (tag) {
    GiftTagFilter.any => l10n.tOr('giftFilterAllShort', 'All'),
    GiftTagFilter.hasTag => l10n.tOr('giftHasTag', 'Has Tag'),
    GiftTagFilter.none => l10n.tOr('giftNoTag', 'No Tag'),
  };
}

String giftsFilterSizeLabel(AppLocalizations l10n, GiftSize? size) {
  if (size == null) return l10n.tOr('giftFilterAllShort', 'All');
  return switch (size) {
    GiftSize.small => l10n.tOr('giftSizeSmall', 'SMALL'),
    GiftSize.medium => l10n.tOr('giftSizeMedium', 'MEDIUM'),
    GiftSize.large => l10n.tOr('giftSizeLarge', 'LARGE'),
  };
}

String giftsFilterPublishedLabel(
  AppLocalizations l10n,
  GiftPublishedFilter published,
) {
  return switch (published) {
    GiftPublishedFilter.any => l10n.tOr('giftFilterAllShort', 'All'),
    GiftPublishedFilter.published => l10n.tOr('giftPublishedNow', 'Published'),
    GiftPublishedFilter.scheduled => l10n.tOr('giftScheduled', 'Scheduled'),
    GiftPublishedFilter.unpublished =>
      l10n.tOr('giftFilterUnpublished', 'Unpublished'),
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

  if (draft.typeFilter != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'type',
        label: giftsFilterTypeLabel(l10n, draft.typeFilter),
        onRemove: () {
          draft.typeFilter = null;
          onChanged();
        },
      ),
    );
  }

  if (draft.tagFilter != GiftTagFilter.any) {
    items.add(
      GiftsActiveFilterItem(
        id: 'tag',
        label: giftsFilterTagLabel(l10n, draft.tagFilter),
        onRemove: () {
          draft.tagFilter = GiftTagFilter.any;
          onChanged();
        },
      ),
    );
  }

  if (draft.sizeFilter != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'size',
        label: giftsFilterSizeLabel(l10n, draft.sizeFilter),
        onRemove: () {
          draft.sizeFilter = null;
          onChanged();
        },
      ),
    );
  }

  if (draft.publishedFilter != GiftPublishedFilter.any) {
    items.add(
      GiftsActiveFilterItem(
        id: 'published',
        label: giftsFilterPublishedLabel(l10n, draft.publishedFilter),
        onRemove: () {
          draft.publishedFilter = GiftPublishedFilter.any;
          onChanged();
        },
      ),
    );
  }

  return items;
}
