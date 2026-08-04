import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/usecases/cancel_auction_usecase.dart';
import '../../domain/usecases/get_all_auctions_usecase.dart';
import '../services/auctions_list_sync.dart';

// ─── Filter enums ─────────────────────────────────────────────────────────────

enum AuctionSortOption {
  newestFirst,
  oldestFirst,
  highestBid,
  lowestBid,
  targetPrice,
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

class LoadMoreAuctionsEvent extends AuctionsEvent {}

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

/// Advanced admin-list filters (host/winner/post/live + has* flags).
class UpdateAuctionAdvancedFiltersEvent extends AuctionsEvent {
  UpdateAuctionAdvancedFiltersEvent({
    this.host,
    this.winner,
    this.postId,
    this.postLabel,
    this.liveId,
    this.liveLabel,
    this.hasWinner,
    this.hasPost,
    this.hasLive,
    this.clearHost = false,
    this.clearWinner = false,
    this.clearPost = false,
    this.clearLive = false,
    this.clearHasWinner = false,
    this.clearHasPost = false,
    this.clearHasLive = false,
  });

  final UserEntity? host;
  final UserEntity? winner;
  final String? postId;
  final String? postLabel;
  final String? liveId;
  final String? liveLabel;
  final bool? hasWinner;
  final bool? hasPost;
  final bool? hasLive;
  final bool clearHost;
  final bool clearWinner;
  final bool clearPost;
  final bool clearLive;
  final bool clearHasWinner;
  final bool clearHasPost;
  final bool clearHasLive;
}

class ClearAuctionAdvancedFiltersEvent extends AuctionsEvent {}

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
    this.hostFilter,
    this.winnerFilter,
    this.postIdFilter,
    this.postLabelFilter,
    this.liveIdFilter,
    this.liveLabelFilter,
    this.hasWinnerFilter,
    this.hasPostFilter,
    this.hasLiveFilter,
    this.isActioning = false,
    this.isFetching = false,
    this.isLoadingMore = false,
    this.actionError,
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
  final UserEntity? hostFilter;
  final UserEntity? winnerFilter;
  final String? postIdFilter;
  final String? postLabelFilter;
  final String? liveIdFilter;
  final String? liveLabelFilter;
  final bool? hasWinnerFilter;
  final bool? hasPostFilter;
  final bool? hasLiveFilter;
  final bool isActioning;
  final bool isFetching;
  final bool isLoadingMore;
  final String? actionError;

  final List<AuctionEntity> displayedAuctions;

  List<AuctionEntity> get displayed => displayedAuctions;

  int get displayedCount => displayedAuctions.length;
  int get totalCount => total;
  bool get hasReachedMax => currentPage >= lastPage;

  int get activeCount => auctions.where((a) => a.status == 'ACTIVE').length;
  int get completedCount =>
      auctions.where((a) => a.status == 'COMPLETED').length;
  int get cancelledCount =>
      auctions.where((a) => a.status == 'CANCELLED').length;
  int get bannedCount => auctions.where((a) => a.status == 'BANNED').length;
  int get disputedCount => auctions.where((a) => a.status == 'DISPUTED').length;
  int get settledCount => auctions.where((a) => a.status == 'SETTLED').length;

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
    UserEntity? hostFilter,
    bool clearHostFilter = false,
    UserEntity? winnerFilter,
    bool clearWinnerFilter = false,
    String? postIdFilter,
    String? postLabelFilter,
    bool clearPostFilter = false,
    String? liveIdFilter,
    String? liveLabelFilter,
    bool clearLiveFilter = false,
    bool? hasWinnerFilter,
    bool clearHasWinnerFilter = false,
    bool? hasPostFilter,
    bool clearHasPostFilter = false,
    bool? hasLiveFilter,
    bool clearHasLiveFilter = false,
    bool? isActioning,
    bool? isFetching,
    bool? isLoadingMore,
    String? actionError,
    bool clearActionError = false,
    List<AuctionEntity>? displayedAuctions,
  }) {
    return AuctionsLoaded(
      auctions: auctions ?? this.auctions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      typeFilter: typeFilter ?? this.typeFilter,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      hostFilter: clearHostFilter ? null : (hostFilter ?? this.hostFilter),
      winnerFilter: clearWinnerFilter
          ? null
          : (winnerFilter ?? this.winnerFilter),
      postIdFilter: clearPostFilter
          ? null
          : (postIdFilter ?? this.postIdFilter),
      postLabelFilter: clearPostFilter
          ? null
          : (postLabelFilter ?? this.postLabelFilter),
      liveIdFilter: clearLiveFilter
          ? null
          : (liveIdFilter ?? this.liveIdFilter),
      liveLabelFilter: clearLiveFilter
          ? null
          : (liveLabelFilter ?? this.liveLabelFilter),
      hasWinnerFilter: clearHasWinnerFilter
          ? null
          : (hasWinnerFilter ?? this.hasWinnerFilter),
      hasPostFilter: clearHasPostFilter
          ? null
          : (hasPostFilter ?? this.hasPostFilter),
      hasLiveFilter: clearHasLiveFilter
          ? null
          : (hasLiveFilter ?? this.hasLiveFilter),
      isActioning: isActioning ?? this.isActioning,
      isFetching: isFetching ?? this.isFetching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
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
    AuctionsListSync? listSync,
  }) : _getAllAuctions = getAllAuctions,
       _cancelAuction = cancelAuction,
       _listSync = listSync,
       super(AuctionsInitial()) {
    on<LoadAllAuctionsEvent>(_onLoad);
    on<GoToAuctionsPageEvent>(_onGoToPage);
    on<LoadMoreAuctionsEvent>(_onLoadMore);
    on<FilterAuctionsEvent>(_onFilter);
    on<UpdateAuctionSearchEvent>(_onUpdateSearch);
    on<UpdateAuctionSortEvent>(_onUpdateSort);
    on<UpdateAuctionTypeFilterEvent>(_onUpdateType);
    on<UpdateAuctionDateRangeEvent>(_onUpdateDateRange);
    on<UpdateAuctionAdvancedFiltersEvent>(_onUpdateAdvancedFilters);
    on<ClearAuctionAdvancedFiltersEvent>(_onClearAdvancedFilters);
    on<AdminCancelAuctionFromListEvent>(_onCancel);
    on<AuctionStatusUpdatedEvent>(_onStatusUpdated);

    final sync = _listSync;
    if (sync != null) {
      _listSyncSub = sync.updates.listen((auction) {
        if (!isClosed) add(AuctionStatusUpdatedEvent(auction));
      });
    }
  }

  final GetAllAuctions _getAllAuctions;
  final AdminCancelAuction _cancelAuction;
  final AuctionsListSync? _listSync;
  StreamSubscription<AuctionEntity>? _listSyncSub;

  static const pageLimit = 20;
  static const _pageLimit = pageLimit;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  bool _busy = false;
  bool _pendingRefresh = false;
  int _loadToken = 0;

  String? _statusFilter;
  String _searchQuery = '';
  AuctionSortOption _sortOption = AuctionSortOption.newestFirst;
  AuctionTypeFilter _typeFilter = AuctionTypeFilter.all;
  DateTimeRange? _dateRange;
  UserEntity? _hostFilter;
  UserEntity? _winnerFilter;
  String? _postIdFilter;
  String? _postLabelFilter;
  String? _liveIdFilter;
  String? _liveLabelFilter;
  bool? _hasWinnerFilter;
  bool? _hasPostFilter;
  bool? _hasLiveFilter;
  int _currentPage = 1;

  String get activeSearchQuery => _searchQuery;
  String? get activeStatusFilter => _statusFilter;
  AuctionSortOption get activeSortOption => _sortOption;
  AuctionTypeFilter get activeTypeFilter => _typeFilter;
  DateTimeRange? get activeDateRange => _dateRange;
  UserEntity? get activeHostFilter => _hostFilter;
  UserEntity? get activeWinnerFilter => _winnerFilter;
  String? get activePostIdFilter => _postIdFilter;
  String? get activePostLabelFilter => _postLabelFilter;
  String? get activeLiveIdFilter => _liveIdFilter;
  String? get activeLiveLabelFilter => _liveLabelFilter;
  bool? get activeHasWinnerFilter => _hasWinnerFilter;
  bool? get activeHasPostFilter => _hasPostFilter;
  bool? get activeHasLiveFilter => _hasLiveFilter;

  AdminAuctionsSortOrder _mapSort(AuctionSortOption sort) => switch (sort) {
    AuctionSortOption.newestFirst => AdminAuctionsSortOrder.newest,
    AuctionSortOption.oldestFirst => AdminAuctionsSortOrder.oldest,
    AuctionSortOption.highestBid => AdminAuctionsSortOrder.highestTotal,
    AuctionSortOption.lowestBid => AdminAuctionsSortOrder.lowestTotal,
    AuctionSortOption.targetPrice => AdminAuctionsSortOrder.targetPrice,
    AuctionSortOption.endingSoon => AdminAuctionsSortOrder.recentlyEnded,
  };

  AdminAuctionsQuery _buildQuery() {
    bool? hasLive = _hasLiveFilter;
    if (_typeFilter == AuctionTypeFilter.live) {
      hasLive = true;
    }

    return AdminAuctionsQuery(
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      status: _statusFilter,
      hostId: _hostFilter?.id,
      winnerId: _winnerFilter?.id,
      postId: _postIdFilter,
      liveId: _liveIdFilter,
      hasWinner: _hasWinnerFilter,
      hasPost: _hasPostFilter,
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
    bool append = false,
  }) async {
    if (page < 1) return;
    if (_busy) {
      // Keep the latest refresh (e.g. clearing search) instead of dropping it.
      if (!append) _pendingRefresh = true;
      return;
    }

    _busy = true;
    final token = ++_loadToken;
    final query = _buildQuery();
    final previous = state;
    if (showLoading && previous is! AuctionsLoaded) {
      emit(AuctionsLoading());
    } else if (previous is AuctionsLoaded) {
      emit(previous.copyWith(isFetching: !append, isLoadingMore: append));
    }

    try {
      final response = await _getAllAuctions(
        page: page,
        limit: _pageLimit,
        query: query,
      );

      // Ignore stale responses after a newer search/filter refresh.
      if (token != _loadToken) return;

      _currentPage = response.currentPage;

      List<AuctionEntity> auctions;
      if (append && previous is AuctionsLoaded) {
        final existingIds = previous.auctions.map((a) => a.id).toSet();
        auctions = [
          ...previous.auctions,
          for (final auction in response.auctions)
            if (!existingIds.contains(auction.id)) auction,
        ];
      } else {
        auctions = response.auctions;
      }

      final displayed = _applyLocalFilters(auctions);

      emit(
        AuctionsLoaded(
          auctions: auctions,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total,
          statusFilter: _statusFilter,
          searchQuery: _searchQuery,
          sortOption: _sortOption,
          typeFilter: _typeFilter,
          dateRange: _dateRange,
          hostFilter: _hostFilter,
          winnerFilter: _winnerFilter,
          postIdFilter: _postIdFilter,
          postLabelFilter: _postLabelFilter,
          liveIdFilter: _liveIdFilter,
          liveLabelFilter: _liveLabelFilter,
          hasWinnerFilter: _hasWinnerFilter,
          hasPostFilter: _hasPostFilter,
          hasLiveFilter: _hasLiveFilter,
          displayedAuctions: displayed,
          isFetching: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (token != _loadToken) return;
      if (previous is AuctionsLoaded) {
        emit(previous.copyWith(isFetching: false, isLoadingMore: false));
      } else {
        emit(AuctionsError(e.toString()));
      }
    } finally {
      _busy = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        if (!isClosed) add(LoadAllAuctionsEvent(refresh: true));
      }
    }
  }

  Future<void> _onLoad(
    LoadAllAuctionsEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is AuctionsLoaded;
    await _fetchPage(emit, page: page, showLoading: !hasData, append: false);
  }

  Future<void> _onGoToPage(
    GoToAuctionsPageEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    await _fetchPage(emit, page: event.page, showLoading: false, append: false);
  }

  Future<void> _onLoadMore(
    LoadMoreAuctionsEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    final current = state;
    if (current is! AuctionsLoaded) return;
    if (current.hasReachedMax || current.isLoadingMore || _busy) return;
    await _fetchPage(
      emit,
      page: current.currentPage + 1,
      showLoading: false,
      append: true,
    );
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
      // Invalidate in-flight search results and always reload the full list.
      _loadToken++;
      if (_busy) {
        _pendingRefresh = true;
      } else {
        add(LoadAllAuctionsEvent(refresh: true));
      }
      return;
    }

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () {
        if (_busy) {
          _pendingRefresh = true;
          return;
        }
        add(LoadAllAuctionsEvent(refresh: true));
      },
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
      emit(
        current.copyWith(
          dateRange: event.dateRange,
          clearDateRange: event.dateRange == null,
          displayedAuctions: _applyLocalFilters(current.auctions),
        ),
      );
    }
  }

  void _onUpdateAdvancedFilters(
    UpdateAuctionAdvancedFiltersEvent event,
    Emitter<AuctionsState> emit,
  ) {
    if (event.clearHost) {
      _hostFilter = null;
    } else if (event.host != null) {
      _hostFilter = event.host;
    }

    if (event.clearWinner) {
      _winnerFilter = null;
    } else if (event.winner != null) {
      _winnerFilter = event.winner;
    }

    if (event.clearPost) {
      _postIdFilter = null;
      _postLabelFilter = null;
    } else if (event.postId != null) {
      _postIdFilter = event.postId;
      _postLabelFilter = event.postLabel;
    }

    if (event.clearLive) {
      _liveIdFilter = null;
      _liveLabelFilter = null;
    } else if (event.liveId != null) {
      _liveIdFilter = event.liveId;
      _liveLabelFilter = event.liveLabel;
    }

    if (event.clearHasWinner) {
      _hasWinnerFilter = null;
    } else if (event.hasWinner != null) {
      _hasWinnerFilter = event.hasWinner;
    }

    if (event.clearHasPost) {
      _hasPostFilter = null;
    } else if (event.hasPost != null) {
      _hasPostFilter = event.hasPost;
    }

    if (event.clearHasLive) {
      _hasLiveFilter = null;
    } else if (event.hasLive != null) {
      _hasLiveFilter = event.hasLive;
    }

    add(LoadAllAuctionsEvent(refresh: true));
  }

  void _onClearAdvancedFilters(
    ClearAuctionAdvancedFiltersEvent event,
    Emitter<AuctionsState> emit,
  ) {
    _hostFilter = null;
    _winnerFilter = null;
    _postIdFilter = null;
    _postLabelFilter = null;
    _liveIdFilter = null;
    _liveLabelFilter = null;
    _hasWinnerFilter = null;
    _hasPostFilter = null;
    _hasLiveFilter = null;
    add(LoadAllAuctionsEvent(refresh: true));
  }

  Future<void> _onCancel(
    AdminCancelAuctionFromListEvent event,
    Emitter<AuctionsState> emit,
  ) async {
    final current = state;
    if (current is! AuctionsLoaded) return;
    emit(current.copyWith(isActioning: true, clearActionError: true));
    try {
      final updated = await _cancelAuction(event.auctionId);
      final idx = current.auctions.indexWhere((a) => a.id == event.auctionId);
      if (idx != -1) {
        final list = List<AuctionEntity>.from(current.auctions);
        list[idx] = updated;
        emit(
          current.copyWith(
            auctions: list,
            displayedAuctions: _applyLocalFilters(list),
            isActioning: false,
            clearActionError: true,
          ),
        );
      } else {
        add(LoadAllAuctionsEvent(page: current.currentPage));
      }
    } catch (e) {
      emit(current.copyWith(isActioning: false, actionError: e.toString()));
    }
  }

  void _onStatusUpdated(
    AuctionStatusUpdatedEvent event,
    Emitter<AuctionsState> emit,
  ) {
    final current = state;
    if (current is! AuctionsLoaded) return;

    final idx = current.auctions.indexWhere((a) => a.id == event.auction.id);
    if (idx == -1) return;

    final updated = List<AuctionEntity>.from(current.auctions);
    updated[idx] = event.auction;
    emit(
      current.copyWith(
        auctions: updated,
        displayedAuctions: _applyLocalFilters(updated),
      ),
    );
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    await _listSyncSub?.cancel();
    return super.close();
  }
}
