import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_entity.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/create_gift_usecase.dart';
import '../../domain/usecases/delete_gift_usecase.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';
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

// ─── States ──────────────────────────────────────────────────────────────────

abstract class GiftsState {}

class GiftsInitial extends GiftsState {}

class GiftsLoading extends GiftsState {}

class GiftsLoaded extends GiftsState {
  GiftsLoaded({
    required this.gifts,
    this.selectedTab = GiftFilterTab.all,
    this.selectedSort = GiftSortType.dateNewToOld,
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
  });

  final List<GiftEntity> gifts;
  final GiftFilterTab selectedTab;
  final GiftSortType selectedSort;

  /// Case-insensitive name filter (empty = no filter).
  final String searchQuery;

  /// Inclusive date-range filter on [GiftEntity.createdAt].
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Inclusive USD price-range filter on [GiftEntity.priceUsd].
  final double? minPriceFilter;
  final double? maxPriceFilter;

  /// Image selected by the admin before submitting the create form.
  final Uint8List? pendingImageBytes;
  final String? pendingImageName;

  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;

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
        sorted.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
        break;
      case GiftSortType.priceHighToLow:
        sorted.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
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
    final price = gift.priceUsd;
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
  }) {
    return GiftsLoaded(
      gifts: gifts ?? this.gifts,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedSort: selectedSort ?? this.selectedSort,
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
  })  : _getAdminGifts = getAdminGifts,
        _createGift = createGift,
        _updateGift = updateGift,
        _deleteGift = deleteGift,
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
  }

  final GetAdminGifts _getAdminGifts;
  final CreateGift _createGift;
  final UpdateGift _updateGift;
  final DeleteGift _deleteGift;

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
        emit(prev.copyWith(gifts: gifts, clearMessages: true));
      } else {
        emit(GiftsLoaded(gifts: gifts));
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
      emit(c.copyWith(selectedTab: event.filter, clearMessages: true));
    }
  }

  void _onChangeSort(
    ChangeGiftSortEvent event,
    Emitter<GiftsState> emit,
  ) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(selectedSort: event.sortType, clearMessages: true));
    }
  }

  void _onSearch(SearchGiftsEvent event, Emitter<GiftsState> emit) {
    final c = state;
    if (c is GiftsLoaded) {
      emit(c.copyWith(searchQuery: event.query, clearMessages: true));
    }
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
      final gifts = c.gifts.where((g) => g.id != event.giftId).toList();
      emit(c.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift deleted successfully',
      ));
    } catch (e) {
      emit(c.copyWith(isActioning: false, errorMessage: e.toString()));
    }
  }
}
