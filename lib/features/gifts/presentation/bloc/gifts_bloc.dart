import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/search_debounce.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../domain/entities/bulk_gift_action_request.dart';
import '../../domain/entities/bulk_gift_action_result.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_reorder_item.dart';
import '../../domain/enums/bulk_gift_action_type.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
import '../../domain/enums/gifts_view_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/bulk_gift_action_usecase.dart';
import '../../domain/usecases/create_gift_usecase.dart';
import '../../domain/usecases/delete_gift_usecase.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../../domain/usecases/reorder_gifts_usecase.dart';
import '../../domain/usecases/update_gift_usecase.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum GiftFilterTab { all, active, inactive }

enum GiftSortType {
  priceLowToHigh,
  priceHighToLow,
  dateOldToNew,
  dateNewToOld,
  sortOrderAsc,
  nameAsc,
}

/// Tag filter for free-form gift tags.
enum GiftTagFilter { any, hasTag, none }

enum GiftPublishedFilter { any, published, scheduled, unpublished }

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class GiftsEvent {}

class LoadAdminGiftsEvent extends GiftsEvent {}

class ChangeGiftTabFilterEvent extends GiftsEvent {
  ChangeGiftTabFilterEvent(this.filter);
  final GiftFilterTab filter;
}

class ChangeGiftSortEvent extends GiftsEvent {
  ChangeGiftSortEvent(this.sortType);
  final GiftSortType sortType;
}

/// Real-time search by gift name (case-insensitive).
class SearchGiftsEvent extends GiftsEvent {
  SearchGiftsEvent(this.query);
  final String query;
}

class _ApplyDebouncedGiftSearchEvent extends GiftsEvent {
  _ApplyDebouncedGiftSearchEvent(this.query);
  final String query;
}

/// Set or clear the date-range filter on createdAt.
/// Pass both [fromDate] and [toDate] as null to clear the range.
class SetDateRangeFilterEvent extends GiftsEvent {
  SetDateRangeFilterEvent({required this.fromDate, required this.toDate});
  final DateTime? fromDate;
  final DateTime? toDate;
}

/// Filter gifts by USD price range (inclusive). Pass null to clear a bound.
class UpdatePriceRangeFilterEvent extends GiftsEvent {
  UpdatePriceRangeFilterEvent({required this.minPrice, required this.maxPrice});
  final double? minPrice;
  final double? maxPrice;
}

/// Filter by [GiftType]. Pass null to clear (show all types).
class SetGiftTypeFilterEvent extends GiftsEvent {
  SetGiftTypeFilterEvent(this.type);
  final GiftType? type;
}

/// Filter by [GiftTagFilter] (includes "any" and "none").
class SetGiftTagFilterEvent extends GiftsEvent {
  SetGiftTagFilterEvent(this.tag);
  final GiftTagFilter tag;
}

/// Filter by [GiftSize]. Pass null to clear (show all sizes).
class SetGiftSizeFilterEvent extends GiftsEvent {
  SetGiftSizeFilterEvent(this.size);
  final GiftSize? size;
}

/// Filter by publish status.
class SetGiftPublishedFilterEvent extends GiftsEvent {
  SetGiftPublishedFilterEvent(this.published);
  final GiftPublishedFilter published;
}

/// Batch-apply every catalog filter/sort at once (used by the filter popup's
/// Apply button so only a single state transition + rebuild happens).
class ApplyGiftsFiltersEvent extends GiftsEvent {
  ApplyGiftsFiltersEvent({
    this.status,
    this.sort,
    this.setTypeFilter = false,
    this.typeFilter,
    this.tagFilter,
    this.setSizeFilter = false,
    this.sizeFilter,
    this.publishedFilter,
    this.setPriceRange = false,
    this.minPrice,
    this.maxPrice,
    this.setDateRange = false,
    this.fromDate,
    this.toDate,
  });

  final GiftFilterTab? status;
  final GiftSortType? sort;
  final bool setTypeFilter;
  final GiftType? typeFilter;
  final GiftTagFilter? tagFilter;
  final bool setSizeFilter;
  final GiftSize? sizeFilter;
  final GiftPublishedFilter? publishedFilter;
  final bool setPriceRange;
  final double? minPrice;
  final double? maxPrice;
  final bool setDateRange;
  final DateTime? fromDate;
  final DateTime? toDate;
}

/// Persists a new drag-and-drop / manual sort order for the given gifts.
class ReorderCatalogGiftsEvent extends GiftsEvent {
  ReorderCatalogGiftsEvent(this.items);

  /// Convenience constructor from an ordered list of gift ids — sort order
  /// is derived from list position (0, 1, 2, …).
  factory ReorderCatalogGiftsEvent.fromOrderedIds(List<String> orderedIds) {
    return ReorderCatalogGiftsEvent([
      for (var i = 0; i < orderedIds.length; i++)
        GiftReorderItem(id: orderedIds[i], sortOrder: i),
    ]);
  }

  final List<GiftReorderItem> items;
}

/// Hold image bytes in BLoC state so the create dialog can preview it.
class SetGiftImageEvent extends GiftsEvent {
  SetGiftImageEvent({required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
}

class ClearGiftImageEvent extends GiftsEvent {}

class CreateGiftEvent extends GiftsEvent {
  CreateGiftEvent(this.data);
  final CreateGiftData data;
}

class UpdateGiftEvent extends GiftsEvent {
  UpdateGiftEvent(this.giftId, this.data);
  final String giftId;
  final UpdateGiftData data;
}

class ToggleGiftActiveEvent extends GiftsEvent {
  ToggleGiftActiveEvent(this.giftId, this.isActive);
  final String giftId;
  final bool isActive;
}

class DeleteGiftEvent extends GiftsEvent {
  DeleteGiftEvent(this.giftId);
  final String giftId;
}

class ChangeGiftsViewEvent extends GiftsEvent {
  ChangeGiftsViewEvent(this.viewType);
  final GiftsViewType viewType;
}

class SelectGiftEvent extends GiftsEvent {
  SelectGiftEvent(this.giftId);
  final String giftId;
}

class DeselectGiftEvent extends GiftsEvent {
  DeselectGiftEvent(this.giftId);
  final String giftId;
}

class SelectAllGiftsEvent extends GiftsEvent {}

class ClearGiftSelectionEvent extends GiftsEvent {}

class ClearGiftsBulkFeedbackEvent extends GiftsEvent {}

class GoToGiftsPageEvent extends GiftsEvent {
  GoToGiftsPageEvent(this.page);
  final int page;
}

class LoadMoreGiftsEvent extends GiftsEvent {}

class DeleteSelectedGiftsEvent extends GiftsEvent {}

class ActivateSelectedGiftsEvent extends GiftsEvent {}

class DeactivateSelectedGiftsEvent extends GiftsEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class GiftsState {}

class GiftsInitial extends GiftsState {}

class GiftsLoading extends GiftsState {}

class GiftsLoaded extends GiftsState {
  GiftsLoaded({
    required this.gifts,
    this.selectedTab = GiftFilterTab.all,
    this.selectedSort = GiftSortType.dateNewToOld,
    this.viewType = GiftsViewType.grid,
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.minPriceFilter,
    this.maxPriceFilter,
    this.typeFilter,
    this.tagFilter = GiftTagFilter.any,
    this.sizeFilter,
    this.publishedFilter = GiftPublishedFilter.any,
    this.pendingImageBytes,
    this.pendingImageName,
    this.isActioning = false,
    this.successMessage,
    this.errorMessage,
    Set<String>? selectedGiftIds,
    this.isPerformingBulkAction = false,
    this.bulkActionMessage,
    this.bulkActionIsError = false,
    this.currentPage = 1,
  }) : selectedGiftIds = Set.unmodifiable(selectedGiftIds ?? const {});

  final List<GiftEntity> gifts;
  final GiftFilterTab selectedTab;
  final GiftSortType selectedSort;
  final GiftsViewType viewType;

  /// Case-insensitive name filter (empty = no filter).
  final String searchQuery;

  /// Inclusive date-range filter on [GiftEntity.createdAt].
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Inclusive USD price-range filter on [GiftEntity.priceCoins].
  final double? minPriceFilter;
  final double? maxPriceFilter;

  /// `null` = all types.
  final GiftType? typeFilter;
  final GiftTagFilter tagFilter;

  /// `null` = all sizes.
  final GiftSize? sizeFilter;
  final GiftPublishedFilter publishedFilter;

  /// Image selected by the admin before submitting the create form.
  final Uint8List? pendingImageBytes;
  final String? pendingImageName;

  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;
  final Set<String> selectedGiftIds;
  final bool isPerformingBulkAction;
  final String? bulkActionMessage;
  final bool bulkActionIsError;

  /// 1-based page for desktop paging / infinite-scroll accumulation.
  final int currentPage;

  /// Cached filter+sort result; invalidated automatically on [copyWith]
  /// because a new [GiftsLoaded] instance is created.
  List<GiftEntity>? _displayedCache;

  bool get isSelectionMode => selectedGiftIds.isNotEmpty;
  int get selectedCount => selectedGiftIds.length;

  bool get allVisibleSelected {
    final items = displayed;
    return items.isNotEmpty &&
        items.every((g) => selectedGiftIds.contains(g.id));
  }

  bool get someVisibleSelected =>
      displayed.any((g) => selectedGiftIds.contains(g.id));

  int get giftsTotalCount => displayed.length;

  int get lastPage {
    final total = giftsTotalCount;
    if (total <= 0) return 1;
    return (total + GiftsBloc.pageLimit - 1) ~/ GiftsBloc.pageLimit;
  }

  bool get hasReachedMaxGifts => currentPage >= lastPage;

  /// Desktop: one page slice. Mobile/tablet: full filtered list (catalog is
  /// already loaded client-side; slivers only build visible children).
  List<GiftEntity> pagedDisplayed({required bool infiniteScroll}) {
    final items = displayed;
    if (items.isEmpty) return const [];

    final pageSize = GiftsBloc.pageLimit;
    if (infiniteScroll) {
      return items;
    }

    final start = (currentPage - 1) * pageSize;
    if (start >= items.length) return const [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  // ── All filters + sort applied here, never in the UI ─────────────────────

  List<GiftEntity> get displayed => _displayedCache ??= _computeDisplayed();

  List<GiftEntity> _computeDisplayed() {
    Iterable<GiftEntity> list = gifts;

    // 1. Tab filter (active / inactive / all)
    switch (selectedTab) {
      case GiftFilterTab.all:
        break;
      case GiftFilterTab.active:
        list = list.where((g) => g.isActive);
        break;
      case GiftFilterTab.inactive:
        list = list.where((g) => !g.isActive);
        break;
    }

    // 2. Name / type / tag search (case-insensitive, partial match)
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((g) =>
          g.name.toLowerCase().contains(q) ||
          g.type.apiValue.toLowerCase().contains(q) ||
          (g.tag?.toLowerCase().contains(q) ?? false));
    }

    // 3. Date-range filter on publishedAt (inclusive, day precision)
    if (fromDate != null || toDate != null) {
      list = list.where((g) {
        final d = g.publishedAt;
        if (d == null) return false;
        final day = DateTime(d.year, d.month, d.day);
        if (fromDate != null) {
          final from =
              DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
          if (day.isBefore(from)) return false;
        }
        if (toDate != null) {
          final to = DateTime(toDate!.year, toDate!.month, toDate!.day);
          if (day.isAfter(to)) return false;
        }
        return true;
      });
    }

    // 4. Price-range filter
    list = _applyPriceFilter(list, minPriceFilter, maxPriceFilter);

    // 5. Type / tag / size / published filters
    if (typeFilter != null) {
      list = list.where((g) => g.type == typeFilter);
    }
    switch (tagFilter) {
      case GiftTagFilter.any:
        break;
      case GiftTagFilter.hasTag:
        list = list.where((g) => g.tag != null && g.tag!.trim().isNotEmpty);
        break;
      case GiftTagFilter.none:
        list = list.where((g) => g.tag == null || g.tag!.trim().isEmpty);
        break;
    }
    if (sizeFilter != null) {
      list = list.where((g) => g.size == sizeFilter);
    }
    switch (publishedFilter) {
      case GiftPublishedFilter.any:
        break;
      case GiftPublishedFilter.published:
        list = list.where((g) => g.isPublishedNow);
        break;
      case GiftPublishedFilter.scheduled:
        list = list.where((g) => g.isScheduled);
        break;
      case GiftPublishedFilter.unpublished:
        list = list.where((g) => g.publishedAt == null);
        break;
    }

    // 6. Sort
    final sorted = list.toList();
    switch (selectedSort) {
      case GiftSortType.priceLowToHigh:
        sorted.sort((a, b) => a.priceCoins.compareTo(b.priceCoins));
        break;
      case GiftSortType.priceHighToLow:
        sorted.sort((a, b) => b.priceCoins.compareTo(a.priceCoins));
        break;
      case GiftSortType.dateOldToNew:
        sorted.sort((a, b) {
          final aD = a.publishedAt ?? DateTime(0);
          final bD = b.publishedAt ?? DateTime(0);
          return aD.compareTo(bD);
        });
        break;
      case GiftSortType.dateNewToOld:
        sorted.sort((a, b) {
          final aD = a.publishedAt ?? DateTime(0);
          final bD = b.publishedAt ?? DateTime(0);
          return bD.compareTo(aD);
        });
        break;
      case GiftSortType.sortOrderAsc:
        sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case GiftSortType.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return sorted;
  }

  static Iterable<GiftEntity> _applyPriceFilter(
    Iterable<GiftEntity> list,
    double? minPrice,
    double? maxPrice,
  ) {
    if (minPrice == null && maxPrice == null) return list;
    return list.where((g) => _matchesPriceRange(g, minPrice, maxPrice));
  }

  static bool _matchesPriceRange(
    GiftEntity gift,
    double? minPrice,
    double? maxPrice,
  ) {
    final price = gift.priceCoins;
    if (minPrice != null && price + 1e-9 < minPrice) return false;
    if (maxPrice != null && price - 1e-9 > maxPrice) return false;
    return true;
  }

  /// Whether any filter other than the default is active.
  bool get hasActiveFilters =>
      selectedTab != GiftFilterTab.all ||
      searchQuery.isNotEmpty ||
      fromDate != null ||
      toDate != null ||
      minPriceFilter != null ||
      maxPriceFilter != null ||
      typeFilter != null ||
      tagFilter != GiftTagFilter.any ||
      sizeFilter != null ||
      publishedFilter != GiftPublishedFilter.any;

  GiftsLoaded copyWith({
    List<GiftEntity>? gifts,
    GiftFilterTab? selectedTab,
    GiftSortType? selectedSort,
    GiftsViewType? viewType,
    String? searchQuery,
    // Use setDateRange = true to explicitly assign fromDate / toDate
    // (needed to set them to null for "clear").
    bool setDateRange = false,
    DateTime? fromDate,
    DateTime? toDate,
    bool setPriceRange = false,
    double? minPriceFilter,
    double? maxPriceFilter,
    bool setTypeFilter = false,
    GiftType? typeFilter,
    GiftTagFilter? tagFilter,
    bool setSizeFilter = false,
    GiftSize? sizeFilter,
    GiftPublishedFilter? publishedFilter,
    Uint8List? pendingImageBytes,
    String? pendingImageName,
    bool clearPendingImage = false,
    bool? isActioning,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    Set<String>? selectedGiftIds,
    bool? isPerformingBulkAction,
    String? bulkActionMessage,
    bool? bulkActionIsError,
    bool clearBulkActionMessage = false,
    int? currentPage,
  }) {
    return GiftsLoaded(
      gifts: gifts ?? this.gifts,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedSort: selectedSort ?? this.selectedSort,
      viewType: viewType ?? this.viewType,
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: setDateRange ? fromDate : (fromDate ?? this.fromDate),
      toDate: setDateRange ? toDate : (toDate ?? this.toDate),
      minPriceFilter: setPriceRange
          ? minPriceFilter
          : (minPriceFilter ?? this.minPriceFilter),
      maxPriceFilter: setPriceRange
          ? maxPriceFilter
          : (maxPriceFilter ?? this.maxPriceFilter),
      typeFilter: setTypeFilter ? typeFilter : (typeFilter ?? this.typeFilter),
      tagFilter: tagFilter ?? this.tagFilter,
      sizeFilter: setSizeFilter ? sizeFilter : (sizeFilter ?? this.sizeFilter),
      publishedFilter: publishedFilter ?? this.publishedFilter,
      pendingImageBytes: clearPendingImage
          ? null
          : (pendingImageBytes ?? this.pendingImageBytes),
      pendingImageName: clearPendingImage
          ? null
          : (pendingImageName ?? this.pendingImageName),
      isActioning: isActioning ?? this.isActioning,
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage:
          clearMessages ? null : (errorMessage ?? this.errorMessage),
      selectedGiftIds: selectedGiftIds ?? this.selectedGiftIds,
      isPerformingBulkAction:
          isPerformingBulkAction ?? this.isPerformingBulkAction,
      bulkActionMessage: clearBulkActionMessage
          ? null
          : (bulkActionMessage ?? this.bulkActionMessage),
      bulkActionIsError: bulkActionIsError ?? this.bulkActionIsError,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class GiftsError extends GiftsState {
  GiftsError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class GiftsBloc extends Bloc<GiftsEvent, GiftsState> {
  GiftsBloc({
    required GetAdminGifts getAdminGifts,
    required CreateGift createGift,
    required UpdateGift updateGift,
    required DeleteGift deleteGift,
    required BulkGiftActionUseCase bulkGiftAction,
    required GetGiftGroupsUseCase getGiftGroups,
    required ReplaceGroupGiftsUseCase replaceGroupGifts,
    required ReorderGiftsUseCase reorderGifts,
  })  : _getAdminGifts = getAdminGifts,
        _createGift = createGift,
        _updateGift = updateGift,
        _deleteGift = deleteGift,
        _bulkGiftAction = bulkGiftAction,
        _getGiftGroups = getGiftGroups,
        _replaceGroupGifts = replaceGroupGifts,
        _reorderGifts = reorderGifts,
        super(GiftsInitial()) {
    on<LoadAdminGiftsEvent>(_onLoad);
    on<ChangeGiftTabFilterEvent>(_onChangeTab);
    on<ChangeGiftSortEvent>(_onChangeSort);
    on<SearchGiftsEvent>(_onSearch);
    on<_ApplyDebouncedGiftSearchEvent>(_onApplyDebouncedSearch);
    on<SetDateRangeFilterEvent>(_onSetDateRange);
    on<UpdatePriceRangeFilterEvent>(_onUpdatePriceRange);
    on<SetGiftTypeFilterEvent>(_onSetTypeFilter);
    on<SetGiftTagFilterEvent>(_onSetTagFilter);
    on<SetGiftSizeFilterEvent>(_onSetSizeFilter);
    on<SetGiftPublishedFilterEvent>(_onSetPublishedFilter);
    on<ApplyGiftsFiltersEvent>(_onApplyFilters);
    on<ReorderCatalogGiftsEvent>(_onReorderGifts);
    on<SetGiftImageEvent>(_onSetImage);
    on<ClearGiftImageEvent>(_onClearImage);
    on<CreateGiftEvent>(_onCreate);
    on<UpdateGiftEvent>(_onUpdate);
    on<ToggleGiftActiveEvent>(_onToggleActive);
    on<DeleteGiftEvent>(_onDelete);
    on<ChangeGiftsViewEvent>(_onChangeView);
    on<SelectGiftEvent>(_onSelectGift);
    on<DeselectGiftEvent>(_onDeselectGift);
    on<SelectAllGiftsEvent>(_onSelectAllGifts);
    on<ClearGiftSelectionEvent>(_onClearSelection);
    on<ClearGiftsBulkFeedbackEvent>(_onClearBulkFeedback);
    on<DeleteSelectedGiftsEvent>(_onBulkAction);
    on<ActivateSelectedGiftsEvent>(_onBulkAction);
    on<DeactivateSelectedGiftsEvent>(_onBulkAction);
    on<GoToGiftsPageEvent>(_onGoToPage);
    on<LoadMoreGiftsEvent>(_onLoadMore);
  }

  final GetAdminGifts _getAdminGifts;
  final CreateGift _createGift;
  final UpdateGift _updateGift;
  final DeleteGift _deleteGift;
  final BulkGiftActionUseCase _bulkGiftAction;
  final GetGiftGroupsUseCase _getGiftGroups;
  final ReplaceGroupGiftsUseCase _replaceGroupGifts;
  final ReorderGiftsUseCase _reorderGifts;

  final SearchDebouncer _searchDebouncer = SearchDebouncer();
  String _pendingSearchQuery = '';

  static const pageLimit = 20;

  GiftsViewType _viewType = GiftsViewType.grid;
  Set<String> _selectedGiftIds = {};

  GiftsViewType get activeViewType => _viewType;
  Set<String> get selectedGiftIds => Set.unmodifiable(_selectedGiftIds);

  void _onChangeView(ChangeGiftsViewEvent event, Emitter<GiftsState> emit) {
    if (_viewType == event.viewType) return;
    _viewType = event.viewType;
    _emitWithUiState(emit);
  }

  void _onSelectGift(SelectGiftEvent event, Emitter<GiftsState> emit) {
    _selectedGiftIds = {..._selectedGiftIds, event.giftId};
    _emitWithUiState(emit);
  }

  void _onDeselectGift(DeselectGiftEvent event, Emitter<GiftsState> emit) {
    _selectedGiftIds = {..._selectedGiftIds}..remove(event.giftId);
    _emitWithUiState(emit);
  }

  void _onSelectAllGifts(
    SelectAllGiftsEvent event,
    Emitter<GiftsState> emit,
  ) {
    final current = state;
    if (current is! GiftsLoaded) return;
    final visibleIds = current.displayed.map((g) => g.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedGiftIds.contains);
    if (allVisibleSelected) {
      _selectedGiftIds = _selectedGiftIds.difference(visibleIds);
    } else {
      _selectedGiftIds = {..._selectedGiftIds, ...visibleIds};
    }
    _emitWithUiState(emit);
  }

  void _onClearSelection(
    ClearGiftSelectionEvent event,
    Emitter<GiftsState> emit,
  ) {
    if (_selectedGiftIds.isEmpty) return;
    _selectedGiftIds = {};
    _emitWithUiState(emit);
  }

  void _onClearBulkFeedback(
    ClearGiftsBulkFeedbackEvent event,
    Emitter<GiftsState> emit,
  ) {
    final current = state;
    if (current is GiftsLoaded && current.bulkActionMessage != null) {
      emit(current.copyWith(clearBulkActionMessage: true));
    }
  }

  void _emitWithUiState(Emitter<GiftsState> emit) {
    final current = state;
    if (current is GiftsLoaded) {
      emit(_withUiState(current));
    }
  }

  GiftsLoaded _withUiState(
    GiftsLoaded current, {
    GiftsLoaded Function(GiftsLoaded)? patch,
  }) {
    final base = patch != null ? patch(current) : current;
    return base.copyWith(
      viewType: _viewType,
      selectedGiftIds: Set<String>.from(_selectedGiftIds),
    );
  }

  Future<void> _onBulkAction(GiftsEvent event, Emitter<GiftsState> emit) async {
    final current = state;
    if (current is! GiftsLoaded || _selectedGiftIds.isEmpty) return;

    final action = _actionForEvent(event);
    if (action == null) return;

    final ids = _selectedGiftIds.toList(growable: false);
    emit(
      _withUiState(
        current.copyWith(
          isPerformingBulkAction: true,
          clearBulkActionMessage: true,
          clearMessages: true,
        ),
      ),
    );

    try {
      final result = await _bulkGiftAction(
        BulkGiftActionRequest(giftIds: ids, action: action),
      );

      final removedIds = result.removedGiftIds.toSet();
      final deactivatedIds = result.deactivatedIds.toSet();
      final succeededIds = result.giftIds.toSet();

      var gifts = current.gifts
          .where((g) => !removedIds.contains(g.id))
          .map((g) {
            if (deactivatedIds.contains(g.id)) {
              return g.copyWith(isActive: false);
            }
            if (!succeededIds.contains(g.id)) return g;
            return switch (action) {
              BulkGiftActionType.activate => g.copyWith(isActive: true),
              BulkGiftActionType.deactivate => g.copyWith(isActive: false),
              BulkGiftActionType.delete => g,
            };
          })
          .toList();

      _selectedGiftIds = _selectedGiftIds
          .difference(removedIds)
          .difference(result.notFoundIds.toSet());

      final message = result.errorMessage ??
          _successMessageFor(action, result);

      emit(
        _withUiState(
          current.copyWith(
            gifts: gifts,
            isPerformingBulkAction: false,
            bulkActionMessage: message,
            bulkActionIsError: !result.isFullSuccess,
          ),
        ),
      );
    } catch (e) {
      emit(
        _withUiState(
          current.copyWith(
            isPerformingBulkAction: false,
            bulkActionMessage: e.toString().replaceFirst('Exception: ', ''),
            bulkActionIsError: true,
          ),
        ),
      );
    }
  }

  BulkGiftActionType? _actionForEvent(GiftsEvent event) => switch (event) {
        DeleteSelectedGiftsEvent() => BulkGiftActionType.delete,
        ActivateSelectedGiftsEvent() => BulkGiftActionType.activate,
        DeactivateSelectedGiftsEvent() => BulkGiftActionType.deactivate,
        _ => null,
      };

  String _successMessageFor(
    BulkGiftActionType action,
    BulkGiftActionResult result,
  ) {
    switch (action) {
      case BulkGiftActionType.delete:
        final parts = <String>['${result.successCount} deleted'];
        if (result.deactivatedCount > 0) {
          parts.add('${result.deactivatedCount} deactivated (in use)');
        }
        if (result.notFoundCount > 0) {
          parts.add('${result.notFoundCount} not found');
        }
        return parts.join('; ');
      case BulkGiftActionType.activate:
        final parts = <String>['${result.successCount} gift(s) activated'];
        if (result.notFoundCount > 0) {
          parts.add('${result.notFoundCount} not found');
        }
        return parts.join('; ');
      case BulkGiftActionType.deactivate:
        final parts = <String>['${result.successCount} gift(s) deactivated'];
        if (result.notFoundCount > 0) {
          parts.add('${result.notFoundCount} not found');
        }
        return parts.join('; ');
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadAdminGiftsEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final prev = state;
    if (prev is! GiftsLoaded) emit(GiftsLoading());
    try {
      final gifts = await _getAdminGifts();
      if (prev is GiftsLoaded) {
        _viewType = prev.viewType;
        emit(_withUiState(
          prev.copyWith(gifts: gifts, currentPage: 1, clearMessages: true),
        ));
      } else {
        emit(GiftsLoaded(gifts: gifts, viewType: _viewType));
      }
    } catch (e) {
      emit(GiftsError(e.toString()));
    }
  }

  // ── Filter / sort ─────────────────────────────────────────────────────────

  void _onChangeTab(
    ChangeGiftTabFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        selectedTab: event.filter,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onChangeSort(
    ChangeGiftSortEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        selectedSort: event.sortType,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onSearch(SearchGiftsEvent event, Emitter<GiftsState> emit) {
    _pendingSearchQuery = event.query;
    _searchDebouncer.run(() {
      if (isClosed) return;
      add(_ApplyDebouncedGiftSearchEvent(_pendingSearchQuery));
    });
  }

  void _onApplyDebouncedSearch(
    _ApplyDebouncedGiftSearchEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        searchQuery: event.query,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onGoToPage(GoToGiftsPageEvent event, Emitter<GiftsState> emit) {
    final c = state;
    if (c is! GiftsLoaded) return;
    final page = event.page.clamp(1, c.lastPage);
    if (page == c.currentPage) return;
    emit(c.copyWith(currentPage: page, clearMessages: true));
  }

  void _onLoadMore(LoadMoreGiftsEvent event, Emitter<GiftsState> emit) {
    final c = state;
    if (c is! GiftsLoaded) return;
    if (c.hasReachedMaxGifts) return;
    emit(c.copyWith(currentPage: c.currentPage + 1, clearMessages: true));
  }

  void _onSetDateRange(
    SetDateRangeFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        setDateRange: true,
        fromDate: event.fromDate,
        toDate: event.toDate,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onUpdatePriceRange(
    UpdatePriceRangeFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is! GiftsLoaded) return;

    final normalized = _normalizePriceRange(event.minPrice, event.maxPrice);
    emit(c.copyWith(
      setPriceRange: true,
      minPriceFilter: normalized.$1,
      maxPriceFilter: normalized.$2,
      currentPage: 1,
      clearMessages: true,
    ));
  }

  /// Swaps min/max when min > max so filtering never breaks.
  (double?, double?) _normalizePriceRange(double? min, double? max) {
    if (min != null && max != null && min > max) {
      return (max, min);
    }
    return (min, max);
  }

  void _onSetTypeFilter(
    SetGiftTypeFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        setTypeFilter: true,
        typeFilter: event.type,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onSetTagFilter(
    SetGiftTagFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        tagFilter: event.tag,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onSetSizeFilter(
    SetGiftSizeFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        setSizeFilter: true,
        sizeFilter: event.size,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onSetPublishedFilter(
    SetGiftPublishedFilterEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        publishedFilter: event.published,
        currentPage: 1,
        clearMessages: true,
      ));
    }
  }

  void _onApplyFilters(
    ApplyGiftsFiltersEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is! GiftsLoaded) return;

    var minPrice = event.minPrice;
    var maxPrice = event.maxPrice;
    if (event.setPriceRange) {
      final normalized = _normalizePriceRange(minPrice, maxPrice);
      minPrice = normalized.$1;
      maxPrice = normalized.$2;
    }

    var fromDate = event.fromDate;
    var toDate = event.toDate;
    if (event.setDateRange && fromDate != null && toDate != null &&
        fromDate.isAfter(toDate)) {
      final temp = fromDate;
      fromDate = toDate;
      toDate = temp;
    }

    emit(c.copyWith(
      selectedTab: event.status,
      selectedSort: event.sort,
      setTypeFilter: event.setTypeFilter,
      typeFilter: event.typeFilter,
      tagFilter: event.tagFilter,
      setSizeFilter: event.setSizeFilter,
      sizeFilter: event.sizeFilter,
      publishedFilter: event.publishedFilter,
      setPriceRange: event.setPriceRange,
      minPriceFilter: minPrice,
      maxPriceFilter: maxPrice,
      setDateRange: event.setDateRange,
      fromDate: fromDate,
      toDate: toDate,
      currentPage: 1,
      clearMessages: true,
    ));
  }

  // ── Reorder ───────────────────────────────────────────────────────────────

  Future<void> _onReorderGifts(
    ReorderCatalogGiftsEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final c = state;
    if (c is! GiftsLoaded || event.items.isEmpty) return;

    emit(c.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _reorderGifts(event.items);
      final updatedById = {for (final g in updated) g.id: g};
      final gifts = c.gifts
          .map((g) => updatedById[g.id] ?? g)
          .toList(growable: false);
      emit(_withUiState(c.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift order updated',
      )));
    } catch (e) {
      emit(c.copyWith(
        isActioning: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  // ── Pending image ─────────────────────────────────────────────────────────

  void _onSetImage(SetGiftImageEvent event, Emitter<GiftsState> emit) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(
        pendingImageBytes: event.bytes,
        pendingImageName: event.name,
        clearMessages: true,
      ));
    }
  }

  void _onClearImage(ClearGiftImageEvent event, Emitter<GiftsState> emit) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(clearPendingImage: true, clearMessages: true));
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> _onCreate(
    CreateGiftEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final c = state;
    if (c is! GiftsLoaded) return;
    emit(c.copyWith(isActioning: true, clearMessages: true));
    try {
      final gift = await _createGift(event.data);
      if (event.data.assignGroupId != null) {
        await _assignGiftToGroup(event.data.assignGroupId!, gift.id);
      }
      emit(c.copyWith(
        gifts: [...c.gifts, gift],
        isActioning: false,
        clearPendingImage: true,
        successMessage: 'Gift "${gift.name}" created successfully',
      ));
    } catch (e) {
      emit(c.copyWith(
        isActioning: false,
        errorMessage: _giftActionErrorMessage(e, isCreate: true),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateGiftEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final c = state;
    if (c is! GiftsLoaded) return;
    emit(c.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _updateGift(event.giftId, event.data);
      await _syncGiftGroupMembership(
        giftId: event.giftId,
        previousGroupId: event.data.previousAssignGroupId,
        nextGroupId: event.data.assignGroupId,
      );
      final gifts =
          c.gifts.map((g) => g.id == event.giftId ? updated : g).toList();
      emit(c.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift updated successfully',
      ));
    } catch (e) {
      emit(c.copyWith(
        isActioning: false,
        errorMessage: _giftActionErrorMessage(e, isCreate: false),
      ));
    }
  }

  Future<void> _onToggleActive(
    ToggleGiftActiveEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final c = state;
    if (c is! GiftsLoaded) return;
    try {
      final updated =
          await _updateGift(event.giftId, UpdateGiftData(isActive: event.isActive));
      final gifts =
          c.gifts.map((g) => g.id == event.giftId ? updated : g).toList();
      emit(c.copyWith(gifts: gifts));
    } catch (e) {
      emit(c.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteGiftEvent event,
    Emitter<GiftsState> emit,
  ) async {
    final c = state;
    if (c is! GiftsLoaded) return;
    emit(c.copyWith(isActioning: true, clearMessages: true));
    try {
      await _deleteGift(event.giftId);
      _selectedGiftIds = {..._selectedGiftIds}..remove(event.giftId);
      final gifts = c.gifts.where((g) => g.id != event.giftId).toList();
      emit(_withUiState(c.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift deleted successfully',
      )));
    } catch (e) {
      emit(c.copyWith(isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _syncGiftGroupMembership({
    required String giftId,
    required String? previousGroupId,
    required String? nextGroupId,
  }) async {
    if (previousGroupId == nextGroupId) return;

    if (previousGroupId != null) {
      await _removeGiftFromGroup(previousGroupId, giftId);
    }
    if (nextGroupId != null) {
      await _assignGiftToGroup(nextGroupId, giftId);
    }
  }

  Future<void> _removeGiftFromGroup(String groupId, String giftId) async {
    final groups = await _getGiftGroups();
    GiftGroupEntity? group;
    for (final candidate in groups) {
      if (candidate.id == groupId) {
        group = candidate;
        break;
      }
    }
    if (group == null) return;

    final remaining = <GiftGroupMembershipItem>[];
    for (final member in group.gifts) {
      if (member.gift.id == giftId) continue;
      remaining.add(
        GiftGroupMembershipItem(
          giftId: member.gift.id,
          sortOrder: remaining.length,
        ),
      );
    }
    await _replaceGroupGifts(groupId, remaining);
  }

  Future<void> _assignGiftToGroup(String groupId, String giftId) async {
    final groups = await _getGiftGroups();
    GiftGroupEntity? group;
    for (final candidate in groups) {
      if (candidate.id == groupId) {
        group = candidate;
        break;
      }
    }
    if (group == null) return;

    final alreadyIn = group.gifts.any((m) => m.gift.id == giftId);
    if (alreadyIn) return;

    // Put the newly assigned gift first (sortOrder 0), matching All-tab
    // placement for new gifts; shift existing members down.
    final existing = [...group.gifts]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final members = [
      GiftGroupMembershipItem(giftId: giftId, sortOrder: 0),
      for (var i = 0; i < existing.length; i++)
        GiftGroupMembershipItem(
          giftId: existing[i].gift.id,
          sortOrder: i + 1,
        ),
    ];
    await _replaceGroupGifts(groupId, members);
  }

  /// Maps backend create/update failures to snackbar-friendly keys/text.
  String _giftActionErrorMessage(Object error, {required bool isCreate}) {
    if (_isDuplicateGiftNameError(error)) {
      return 'giftNameAlreadyExists';
    }
    return ApiErrorMessages.from(error);
  }

  bool _isDuplicateGiftNameError(Object error) {
    final message = ApiErrorMessages.from(error).toLowerCase();
    final looksLikeDuplicateName = message.contains('duplicate') ||
        message.contains('already exist') ||
        message.contains('already exists') ||
        message.contains('unique') ||
        (message.contains('name') &&
            (message.contains('exist') ||
                message.contains('taken') ||
                message.contains('in use') ||
                message.contains('conflict')));

    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 409) return true;
      if ((code == 400 || code == 422) && looksLikeDuplicateName) return true;
    }

    return looksLikeDuplicateName;
  }

  @override
  Future<void> close() {
    _searchDebouncer.dispose();
    return super.close();
  }
}
