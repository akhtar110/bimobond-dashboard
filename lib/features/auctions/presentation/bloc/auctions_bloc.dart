import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/usecases/cancel_auction_usecase.dart';
import '../../domain/usecases/get_all_auctions_usecase.dart';

// ─── Filter enums ─────────────────────────────────────────────────────────────

enum AuctionSortOption {
  newestFirst,
  oldestFirst,
  highestBid,
  lowestBid,
  mostViewed,
  endingSoon,
}

enum AuctionTypeFilter { all, fixed, timed, live }

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuctionsEvent {}

class LoadAllAuctionsEvent extends AuctionsEvent {
  LoadAllAuctionsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class GoToAuctionsPageEvent extends AuctionsEvent {
  GoToAuctionsPageEvent(this.page);
  final int page;
}

class FilterAuctionsEvent extends AuctionsEvent {
  FilterAuctionsEvent(this.status);
  final String? status;
}

class UpdateAuctionSearchEvent extends AuctionsEvent {
  UpdateAuctionSearchEvent(this.query);
  final String query;
}

class UpdateAuctionSortEvent extends AuctionsEvent {
  UpdateAuctionSortEvent(this.sortOption);
  final AuctionSortOption sortOption;
}

class UpdateAuctionTypeFilterEvent extends AuctionsEvent {
  UpdateAuctionTypeFilterEvent(this.typeFilter);
  final AuctionTypeFilter typeFilter;
}

class UpdateAuctionDateRangeEvent extends AuctionsEvent {
  UpdateAuctionDateRangeEvent(this.dateRange);
  final DateTimeRange? dateRange;
}

class AdminCancelAuctionFromListEvent extends AuctionsEvent {
  AdminCancelAuctionFromListEvent(this.auctionId);
  final String auctionId;
}

class AuctionStatusUpdatedEvent extends AuctionsEvent {
  AuctionStatusUpdatedEvent(this.auction);
  final AuctionEntity auction;
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuctionsState {}

class AuctionsInitial extends AuctionsState {}

class AuctionsLoading extends AuctionsState {}

class AuctionsLoaded extends AuctionsState {
  AuctionsLoaded({
    required this.auctions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.statusFilter,
    this.searchQuery = '',
    this.sortOption = AuctionSortOption.newestFirst,
    this.typeFilter = AuctionTypeFilter.all,
    this.dateRange,
    this.isActioning = false,
    this.isFetching = false,
    List<AuctionEntity>? displayedAuctions,
  }) : displayedAuctions = displayedAuctions ?? auctions;

  final List<AuctionEntity> auctions;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? statusFilter;
  final String searchQuery;
  final AuctionSortOption sortOption;
  final AuctionTypeFilter typeFilter;
  final DateTimeRange? dateRange;
  final bool isActioning;
  final bool isFetching;

  final List<AuctionEntity> displayedAuctions;

  List<AuctionEntity> get displayed => displayedAuctions;

  int get displayedCount => displayedAuctions.length;
  int get totalCount => total;

  int get activeCount =>
      auctions.where((a) => a.status == 'ACTIVE').length;
  int get completedCount =>
      auctions.where((a) => a.status == 'COMPLETED').length;
  int get cancelledCount =>
      auctions.where((a) => a.status == 'CANCELLED').length;
  int get bannedCount => auctions.where((a) => a.status == 'BANNED').length;

  AuctionsLoaded copyWith({
    List<AuctionEntity>? auctions,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    AuctionSortOption? sortOption,
    AuctionTypeFilter? typeFilter,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    bool? isActioning,
    bool? isFetching,
    List<AuctionEntity>? displayedAuctions,
  }) {
    return AuctionsLoaded(
      auctions: auctions ?? this.auctions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      typeFilter: typeFilter ?? this.typeFilter,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      isActioning: isActioning ?? this.isActioning,
      isFetching: isFetching ?? this.isFetching,
      displayedAuctions: displayedAuctions ?? this.displayedAuctions,
    );
  }
}

class AuctionsError extends AuctionsState {
  AuctionsError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class AuctionsBloc extends Bloc<AuctionsEvent, AuctionsState> {
  AuctionsBloc({
    required GetAllAuctions getAllAuctions,
    required AdminCancelAuction cancelAuction,
  })  : _getAllAuctions = getAllAuctions,
        _cancelAuction = cancelAuction,
        super(AuctionsInitial()) {
    on<LoadAllAuctionsEvent>(_onLoad);
    on<GoToAuctionsPageEvent>(_onGoToPage);
    on<FilterAuctionsEvent>(_onFilter);
    on<UpdateAuctionSearchEvent>(_onUpdateSearch);
    on<UpdateAuctionSortEvent>(_onUpdateSort);
    on<UpdateAuctionTypeFilterEvent>(_onUpdateType);
    on<UpdateAuctionDateRangeEvent>(_onUpdateDateRange);
    on<AdminCancelAuctionFromListEvent>(_onCancel);
    on<AuctionStatusUpdatedEvent>(_onStatusUpdated);
  }

  final GetAllAuctions _getAllAuctions;
  final AdminCancelAuction _cancelAuction;

  static const _pageLimit = 20;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  bool _busy = false;

  String? _statusFilter;
  String _searchQuery = '';
  AuctionSortOption _sortOption = AuctionSortOption.newestFirst;
  AuctionTypeFilter _typeFilter = AuctionTypeFilter.all;
  DateTimeRange? _dateRange;
  int _currentPage = 1;

  AdminAuctionsSortOrder _mapSort(AuctionSortOption sort) => switch (sort) {
        AuctionSortOption.newestFirst => AdminAuctionsSortOrder.newest,
        AuctionSortOption.oldestFirst => AdminAuctionsSortOrder.oldest,
        AuctionSortOption.highestBid => AdminAuctionsSortOrder.highestTotal,
        AuctionSortOption.lowestBid => AdminAuctionsSortOrder.lowestTotal,
        AuctionSortOption.mostViewed => AdminAuctionsSortOrder.newest,
        AuctionSortOption.endingSoon => AdminAuctionsSortOrder.recentlyEnded,
      };

  AdminAuctionsQuery _buildQuery() {
    bool? hasLive;
    if (_typeFilter == AuctionTypeFilter.live) {
      hasLive = true;
    }

    return AdminAuctionsQuery(
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      status: _statusFilter,
      hasLive: hasLive,
      sort: _mapSort(_sortOption),
    );
  }

  AuctionTypeFilter _inferAuctionType(AuctionEntity auction) {
    if (auction.liveId != null && auction.liveId!.isNotEmpty) {
      return AuctionTypeFilter.live;
    }
    if (auction.endedAt != null) {
      return AuctionTypeFilter.timed;
    }
    return AuctionTypeFilter.fixed;
  }

  List<AuctionEntity> _applyLocalFilters(List<AuctionEntity> auctions) {
    Iterable<AuctionEntity> results = auctions;

    if (_typeFilter == AuctionTypeFilter.fixed ||
        _typeFilter == AuctionTypeFilter.timed) {
      results = results.where((a) => _inferAuctionType(a) == _typeFilter);
    }

    final range = _dateRange;
    if (range != null) {
      results = results.where((a) {
        final date = a.startedAt;
        return !date.isBefore(range.start) &&
            !date.isAfter(range.end.add(const Duration(days: 1)));
      });
    }

    return results.toList();
  }

  Future<void> _fetchPage(
    Emitter<AuctionsState> emit, {
    required int page,
    bool showLoading = true,
  }) async {
    if (_busy) return;
    if (page < 1) return;

    _busy = true;
    final previous = state;
    if (showLoading && previous is! AuctionsLoaded) {
      emit(AuctionsLoading());
    } else if (previous is AuctionsLoaded) {
      emit(previous.copyWith(isFetching: true));
    }

    try {
      final response = await _getAllAuctions(
        page: page,
        limit: _pageLimit,
        query: _buildQuery(),
      );

      _currentPage = response.currentPage;
      final displayed = _applyLocalFilters(response.auctions);

      emit(AuctionsLoaded(
        auctions: response.auctions,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
        statusFilter: _statusFilter,
        searchQuery: _searchQuery,
        sortOption: _sortOption,
        typeFilter: _typeFilter,
        dateRange: _dateRange,
        displayedAuctions: displayed,
        isFetching: false,
      ));
    } catch (e) {
      if (previous is AuctionsLoaded) {
        emit(previous.copyWith(isFetching: false));
      } else {
        emit(AuctionsError(e.toString()));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onLoad(
    LoadAllAuctionsEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is AuctionsLoaded;
    await _fetchPage(
      emit,
      page: page,
      showLoading: !hasData,
    );
  }

  Future<void> _onGoToPage(
    GoToAuctionsPageEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    await _fetchPage(emit, page: event.page, showLoading: false);
  }

  void _onFilter(FilterAuctionsEvent event, Emitter<AuctionsState> emit) {
    _statusFilter = event.status;
    add(LoadAllAuctionsEvent(refresh: true));
  }

  void _onUpdateSearch(
    UpdateAuctionSearchEvent event,
    Emitter<AuctionsState> emit,
  ) {
    _searchQuery = event.query;
    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      add(LoadAllAuctionsEvent(refresh: true));
      return;
    }

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(LoadAllAuctionsEvent(refresh: true)),
    );
  }

  void _onUpdateSort(
    UpdateAuctionSortEvent event,
    Emitter<AuctionsState> emit,
  ) {
    _sortOption = event.sortOption;
    add(LoadAllAuctionsEvent(refresh: true));
  }

  void _onUpdateType(
    UpdateAuctionTypeFilterEvent event,
    Emitter<AuctionsState> emit,
  ) {
    _typeFilter = event.typeFilter;
    add(LoadAllAuctionsEvent(refresh: true));
  }

  void _onUpdateDateRange(
    UpdateAuctionDateRangeEvent event,
    Emitter<AuctionsState> emit,
  ) {
    _dateRange = event.dateRange;
    final current = state;
    if (current is AuctionsLoaded) {
      emit(current.copyWith(
        dateRange: event.dateRange,
        clearDateRange: event.dateRange == null,
        displayedAuctions: _applyLocalFilters(current.auctions),
      ));
    }
  }

  Future<void> _onCancel(
    AdminCancelAuctionFromListEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    final current = state;
    if (current is! AuctionsLoaded) return;
    emit(current.copyWith(isActioning: true));
    try {
      await _cancelAuction(event.auctionId);
      add(LoadAllAuctionsEvent(page: current.currentPage));
    } catch (e) {
      emit(current.copyWith(isActioning: false));
    }
  }

  void _onStatusUpdated(
    AuctionStatusUpdatedEvent event,
    Emitter<AuctionsState> emit,
  ) {
    final current = state;
    if (current is! AuctionsLoaded) return;

    final idx =
        current.auctions.indexWhere((a) => a.id == event.auction.id);
    if (idx == -1) return;

    final updated = List<AuctionEntity>.from(current.auctions);
    updated[idx] = event.auction;
    emit(current.copyWith(
      auctions: updated,
      displayedAuctions: _applyLocalFilters(updated),
    ));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
