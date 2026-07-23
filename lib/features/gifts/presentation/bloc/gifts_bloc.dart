import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bulk_gift_action_request.dart';
import '../../domain/entities/bulk_gift_action_result.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/bulk_gift_action_type.dart';
import '../../domain/enums/gifts_view_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/bulk_gift_action_usecase.dart';
import '../../domain/usecases/create_gift_usecase.dart';
import '../../domain/usecases/delete_gift_usecase.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../../domain/usecases/update_gift_usecase.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum GiftFilterTab { all, active, inactive }

enum GiftSortType {
  priceLowToHigh,
  priceHighToLow,
  dateOldToNew,
  dateNewToOld,
}

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

  bool get isSelectionMode => selectedGiftIds.isNotEmpty;
  int get selectedCount => selectedGiftIds.length;

  bool get allVisibleSelected =>
      displayed.isNotEmpty &&
      displayed.every((g) => selectedGiftIds.contains(g.id));

  bool get someVisibleSelected =>
      displayed.any((g) => selectedGiftIds.contains(g.id));

  int get giftsTotalCount => displayed.length;

  int get lastPage {
    final total = giftsTotalCount;
    if (total <= 0) return 1;
    return (total + GiftsBloc.pageLimit - 1) ~/ GiftsBloc.pageLimit;
  }

  bool get hasReachedMaxGifts => currentPage >= lastPage;

  /// Desktop: one page slice. Infinite scroll: first N pages accumulated.
  List<GiftEntity> pagedDisplayed({required bool infiniteScroll}) {
    final items = displayed;
    if (items.isEmpty) return const [];

    final pageSize = GiftsBloc.pageLimit;
    if (infiniteScroll) {
      final end = (currentPage * pageSize).clamp(0, items.length);
      return items.sublist(0, end);
    }

    final start = (currentPage - 1) * pageSize;
    if (start >= items.length) return const [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  // ── All filters + sort applied here, never in the UI ─────────────────────

  List<GiftEntity> get displayed {
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

    // 2. Name search (case-insensitive, partial match)
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((g) => g.name.toLowerCase().contains(q));
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

    // 5. Sort
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
      maxPriceFilter != null;

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
  })  : _getAdminGifts = getAdminGifts,
        _createGift = createGift,
        _updateGift = updateGift,
        _deleteGift = deleteGift,
        _bulkGiftAction = bulkGiftAction,
        _getGiftGroups = getGiftGroups,
        _replaceGroupGifts = replaceGroupGifts,
        super(GiftsInitial()) {
    on<LoadAdminGiftsEvent>(_onLoad);
    on<ChangeGiftTabFilterEvent>(_onChangeTab);
    on<ChangeGiftSortEvent>(_onChangeSort);
    on<SearchGiftsEvent>(_onSearch);
    on<SetDateRangeFilterEvent>(_onSetDateRange);
    on<UpdatePriceRangeFilterEvent>(_onUpdatePriceRange);
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
    return switch (action) {
      BulkGiftActionType.delete => result.deactivatedCount > 0
          ? 'Deleted ${result.successCount} gift(s); '
              '${result.deactivatedCount} deactivated (in use)'
          : '${result.successCount} gift(s) deleted',
      BulkGiftActionType.activate =>
        '${result.successCount} gift(s) activated',
      BulkGiftActionType.deactivate =>
        '${result.successCount} gift(s) deactivated',
    };
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
      emit(c.copyWith(isActioning: false, errorMessage: e.toString()));
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
      final gifts =
          c.gifts.map((g) => g.id == event.giftId ? updated : g).toList();
      emit(c.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift updated successfully',
      ));
    } catch (e) {
      emit(c.copyWith(isActioning: false, errorMessage: e.toString()));
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

    final members = [
      for (final member in group.gifts)
        GiftGroupMembershipItem(
          giftId: member.gift.id,
          sortOrder: member.sortOrder,
        ),
      GiftGroupMembershipItem(
        giftId: giftId,
        sortOrder: group.gifts.length,
      ),
    ];
    await _replaceGroupGifts(groupId, members);
  }
}
