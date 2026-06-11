import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auction_report_entities.dart';
import '../../domain/entities/auction_reports_query.dart';
import '../../domain/usecases/get_auction_reports_list.dart';
import '../../domain/usecases/get_auction_reports_overview.dart';

part 'auction_reports_event.dart';
part 'auction_reports_state.dart';

class AuctionReportsBloc extends Bloc<AuctionReportsEvent, AuctionReportsState> {
  AuctionReportsBloc({
    required GetAuctionReportsList getAuctionReportsList,
    required GetAuctionReportsOverview getAuctionReportsOverview,
  })  : _getAuctionReportsList = getAuctionReportsList,
        _getAuctionReportsOverview = getAuctionReportsOverview,
        super(AuctionReportsInitial()) {
    on<LoadAuctionReportsEvent>(_onLoad);
    on<GoToAuctionReportsPageEvent>(_onGoToPage);
    on<UpdateAuctionReportsSearchEvent>(_onUpdateSearch);
    on<UpdateAuctionReportsFiltersEvent>(_onUpdateFilters);
    on<UpdateAuctionReportsSortEvent>(_onUpdateSort);
    on<ClearAuctionReportsFiltersEvent>(_onClearFilters);
    on<LoadAuctionReportsOverviewEvent>(_onLoadOverview);
  }

  final GetAuctionReportsList _getAuctionReportsList;
  final GetAuctionReportsOverview _getAuctionReportsOverview;

  static const _pageLimit = 20;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  bool _busy = false;

  AuctionReportsListQuery _query = const AuctionReportsListQuery();
  String _searchQuery = '';
  int _currentPage = 1;
  int _overviewDays = 30;

  Future<void> _fetchPage(
    Emitter<AuctionReportsState> emit, {
    required int page,
    bool showLoading = true,
  }) async {
    if (_busy) return;
    if (page < 1) return;

    _busy = true;
    final previous = state;
    if (showLoading && previous is! AuctionReportsLoaded) {
      emit(AuctionReportsLoading());
    } else if (previous is AuctionReportsLoaded) {
      emit(previous.copyWith(isFetching: true));
    }

    try {
      final response = await _getAuctionReportsList(
        page: page,
        limit: _pageLimit,
        query: _query,
      );

      _currentPage = response.page;

      emit(AuctionReportsLoaded(
        auctions: response.items,
        currentPage: response.page,
        lastPage: response.lastPage,
        total: response.total,
        query: _query,
        searchQuery: _searchQuery,
        isFetching: false,
        overview: previous is AuctionReportsLoaded ? previous.overview : null,
        overviewDays: _overviewDays,
      ));
    } catch (e) {
      if (previous is AuctionReportsLoaded) {
        emit(previous.copyWith(isFetching: false));
      } else {
        emit(AuctionReportsError(e.toString()));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onLoad(
    LoadAuctionReportsEvent event,
    Emitter<AuctionReportsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is AuctionReportsLoaded;
    await _fetchPage(
      emit,
      page: page,
      showLoading: !hasData,
    );
  }

  Future<void> _onGoToPage(
    GoToAuctionReportsPageEvent event,
    Emitter<AuctionReportsState> emit,
  ) async {
    await _fetchPage(emit, page: event.page, showLoading: false);
  }

  void _onUpdateSearch(
    UpdateAuctionReportsSearchEvent event,
    Emitter<AuctionReportsState> emit,
  ) {
    _searchQuery = event.query;
    _query = _query.copyWith(
      search: event.query.trim().isEmpty ? null : event.query.trim(),
      clearSearch: event.query.trim().isEmpty,
    );

    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      add(LoadAuctionReportsEvent(refresh: true));
      return;
    }

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(LoadAuctionReportsEvent(refresh: true)),
    );
  }

  void _onUpdateFilters(
    UpdateAuctionReportsFiltersEvent event,
    Emitter<AuctionReportsState> emit,
  ) {
    _query = event.query;
    add(LoadAuctionReportsEvent(refresh: true));
  }

  void _onUpdateSort(
    UpdateAuctionReportsSortEvent event,
    Emitter<AuctionReportsState> emit,
  ) {
    _query = _query.copyWith(sort: event.sort);
    add(LoadAuctionReportsEvent(refresh: true));
  }

  void _onClearFilters(
    ClearAuctionReportsFiltersEvent event,
    Emitter<AuctionReportsState> emit,
  ) {
    _searchQuery = '';
    _query = const AuctionReportsListQuery();
    add(LoadAuctionReportsEvent(refresh: true));
  }

  Future<void> _onLoadOverview(
    LoadAuctionReportsOverviewEvent event,
    Emitter<AuctionReportsState> emit,
  ) async {
    _overviewDays = event.days;
    final current = state;
    if (current is AuctionReportsLoaded) {
      emit(current.copyWith(isOverviewLoading: true));
    }

    try {
      final overview = await _getAuctionReportsOverview(
        ReportPeriodQuery(days: event.days),
      );
      final loaded = state;
      if (loaded is AuctionReportsLoaded) {
        emit(loaded.copyWith(
          overview: overview,
          isOverviewLoading: false,
          overviewDays: event.days,
        ));
      } else {
        emit(AuctionReportsLoaded(
          auctions: const [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
          query: _query,
          overview: overview,
          overviewDays: event.days,
        ));
      }
    } catch (e) {
      final loaded = state;
      if (loaded is AuctionReportsLoaded) {
        emit(loaded.copyWith(isOverviewLoading: false));
      }
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
