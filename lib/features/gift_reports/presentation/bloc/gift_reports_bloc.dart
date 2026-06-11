import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_report_entities.dart';
import '../../domain/usecases/get_gift_reports_list_usecase.dart';
import '../../domain/usecases/get_gift_reports_overview_usecase.dart';

part 'gift_reports_event.dart';
part 'gift_reports_state.dart';

class GiftReportsBloc extends Bloc<GiftReportsEvent, GiftReportsState> {
  GiftReportsBloc({
    required GetGiftReportsOverview getOverview,
    required GetGiftReportsList getList,
  })  : _getOverview = getOverview,
        _getList = getList,
        super(GiftReportsInitial()) {
    on<LoadGiftReportsOverviewEvent>(_onLoadOverview);
    on<LoadGiftReportsListEvent>(_onLoadList);
    on<GoToGiftReportsPageEvent>(_onGoToPage);
    on<UpdateGiftReportsSearchEvent>(_onUpdateSearch);
    on<UpdateGiftReportsSortEvent>(_onUpdateSort);
    on<UpdateGiftReportsActiveFilterEvent>(_onUpdateActiveFilter);
    on<SetGiftReportsDateRangeFilterEvent>(_onSetDateRange);
    on<UpdateGiftReportsPriceRangeFilterEvent>(_onUpdatePriceRange);
    on<ChangeGiftReportsDaysEvent>(_onChangeDays);
    on<RefreshGiftReportsEvent>(_onRefresh);
    on<ReapplyGiftReportsFiltersEvent>(_onReapplyFilters);
  }

  final GetGiftReportsOverview _getOverview;
  final GetGiftReportsList _getList;

  static const _pageLimit = 20;
  static const _searchDebounceMs = 300;
  static const _catalogPageSize = 100;
  static const _maxCatalogPages = 20;

  Timer? _searchDebounce;
  bool _busy = false;

  int _currentPage = 1;
  int _days = 30;
  String _searchQuery = '';
  GiftReportsSort _sort = GiftReportsSort.newest;
  bool? _isActiveFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minPriceFilter;
  double? _maxPriceFilter;
  List<GiftReportListItemEntity> _catalogItems = const [];

  GiftReportPeriodQuery get _periodQuery =>
      GiftReportPeriodQuery(days: _days);

  GiftReportsLoaded? get _loaded =>
      state is GiftReportsLoaded ? state as GiftReportsLoaded : null;

  Future<void> _onLoadOverview(
    LoadGiftReportsOverviewEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    final seed = _loaded ??
        GiftReportsLoaded(
          items: const [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
          days: _days,
        );

    if (state is GiftReportsLoaded) {
      emit(
        (state as GiftReportsLoaded)
            .copyWith(isOverviewLoading: true, clearOverviewError: true),
      );
    } else if (state is! GiftReportsLoading) {
      emit(seed.copyWith(isOverviewLoading: true, clearOverviewError: true));
    }

    try {
      final overview = await _getOverview(_periodQuery);
      final latest = _loaded ?? seed;
      emit(
        latest.copyWith(
          overview: overview,
          isOverviewLoading: false,
          clearOverviewError: true,
        ),
      );
    } catch (e) {
      final latest = _loaded ?? seed;
      emit(
        latest.copyWith(
          isOverviewLoading: false,
          overviewError: e.toString(),
        ),
      );
    }
  }

  Future<List<GiftReportListItemEntity>> _fetchCatalog() async {
    final all = <GiftReportListItemEntity>[];
    var page = 1;

    while (page <= _maxCatalogPages) {
      final response = await _getList(
        page: page,
        limit: _catalogPageSize,
        query: const GiftReportsListQuery(sort: GiftReportsSort.newest),
      );
      all.addAll(response.items);
      if (page >= response.lastPage || response.items.isEmpty) break;
      page++;
    }

    return all;
  }

  List<GiftReportListItemEntity> _filterCatalog() {
    Iterable<GiftReportListItemEntity> list = _catalogItems;

    if (_isActiveFilter != null) {
      list = list.where((item) => item.isActive == _isActiveFilter);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((item) => item.name.toLowerCase().contains(query));
    }

    if (_fromDate != null || _toDate != null) {
      list = list.where((item) {
        final publishedAt = item.publishedAt;
        if (publishedAt == null) return false;
        final day = DateTime(
          publishedAt.year,
          publishedAt.month,
          publishedAt.day,
        );
        if (_fromDate != null) {
          final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
          if (day.isBefore(from)) return false;
        }
        if (_toDate != null) {
          final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
          if (day.isAfter(to)) return false;
        }
        return true;
      });
    }

    if (_minPriceFilter != null || _maxPriceFilter != null) {
      list = list.where(
        (item) => _matchesPriceRange(
          item.priceUsd,
          _minPriceFilter,
          _maxPriceFilter,
        ),
      );
    }

    final sorted = list.toList();
    switch (_sort) {
      case GiftReportsSort.newest:
        sorted.sort((a, b) {
          final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      case GiftReportsSort.oldest:
        sorted.sort((a, b) {
          final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
      case GiftReportsSort.priceAsc:
        sorted.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
      case GiftReportsSort.priceDesc:
        sorted.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
      case GiftReportsSort.mostSent:
        sorted.sort(
          (a, b) => b.counts.transactions.compareTo(a.counts.transactions),
        );
      case GiftReportsSort.mostRevenue:
        sorted.sort(
          (a, b) => b.revenue.spendUsd.compareTo(a.revenue.spendUsd),
        );
      case GiftReportsSort.name:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }

    return sorted;
  }

  bool _matchesPriceRange(double price, double? minPrice, double? maxPrice) {
    if (minPrice != null && price + 1e-9 < minPrice) return false;
    if (maxPrice != null && price - 1e-9 > maxPrice) return false;
    return true;
  }

  void _emitFilteredPage(
    Emitter<GiftReportsState> emit, {
    int? page,
    GiftReportsLoaded? base,
  }) {
    final filtered = _filterCatalog();
    final total = filtered.length;
    final lastPage = math.max(1, (total / _pageLimit).ceil());
    final currentPage = math.min(page ?? _currentPage, lastPage).clamp(1, lastPage);
    _currentPage = currentPage;

    final start = (currentPage - 1) * _pageLimit;
    final items = filtered
        .skip(start)
        .take(_pageLimit)
        .toList(growable: false);

    final previous = base ?? _loaded;
    final seed = previous ??
        GiftReportsLoaded(
          items: const [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
          days: _days,
        );

    emit(
      seed.copyWith(
        items: items,
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
        days: _days,
        searchQuery: _searchQuery,
        sort: _sort,
        isActiveFilter: _isActiveFilter,
        setDateRange: true,
        fromDate: _fromDate,
        toDate: _toDate,
        setPriceRange: true,
        minPriceFilter: _minPriceFilter,
        maxPriceFilter: _maxPriceFilter,
        isListFetching: false,
        clearListError: true,
      ),
    );
  }

  Future<void> _refreshCatalog(
    Emitter<GiftReportsState> emit, {
    required int page,
    bool showLoading = true,
  }) async {
    if (_busy) return;
    if (page < 1) return;

    _busy = true;
    final previous = state;
    if (showLoading && previous is! GiftReportsLoaded) {
      emit(GiftReportsLoading());
    } else if (previous is GiftReportsLoaded) {
      emit(previous.copyWith(isListFetching: true, clearListError: true));
    }

    try {
      _catalogItems = await _fetchCatalog();
      _emitFilteredPage(
        emit,
        page: page,
        base: previous is GiftReportsLoaded ? previous : null,
      );
    } catch (e) {
      if (previous is GiftReportsLoaded) {
        emit(
          previous.copyWith(
            isListFetching: false,
            listError: e.toString(),
          ),
        );
      } else {
        emit(GiftReportsError(e.toString()));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onLoadList(
    LoadGiftReportsListEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is GiftReportsLoaded;
    await _refreshCatalog(emit, page: page, showLoading: !hasData);
  }

  Future<void> _onGoToPage(
    GoToGiftReportsPageEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    if (_catalogItems.isEmpty) {
      await _refreshCatalog(emit, page: event.page, showLoading: false);
      return;
    }
    _emitFilteredPage(emit, page: event.page);
  }

  void _onUpdateSearch(
    UpdateGiftReportsSearchEvent event,
    Emitter<GiftReportsState> emit,
  ) {
    _searchQuery = event.query;
    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      _currentPage = 1;
      _emitFilteredPage(emit, page: 1);
      return;
    }

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(ReapplyGiftReportsFiltersEvent()),
    );
  }

  void _onReapplyFilters(
    ReapplyGiftReportsFiltersEvent event,
    Emitter<GiftReportsState> emit,
  ) {
    _currentPage = 1;
    _emitFilteredPage(emit, page: 1);
  }

  void _onUpdateSort(
    UpdateGiftReportsSortEvent event,
    Emitter<GiftReportsState> emit,
  ) {
    _sort = event.sort;
    _currentPage = 1;
    _emitFilteredPage(emit, page: 1);
  }

  void _onUpdateActiveFilter(
    UpdateGiftReportsActiveFilterEvent event,
    Emitter<GiftReportsState> emit,
  ) {
    _isActiveFilter = event.isActive;
    _currentPage = 1;
    _emitFilteredPage(emit, page: 1);
  }

  void _onSetDateRange(
    SetGiftReportsDateRangeFilterEvent event,
    Emitter<GiftReportsState> emit,
  ) {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _currentPage = 1;
    _emitFilteredPage(emit, page: 1);
  }

  Future<void> _onUpdatePriceRange(
    UpdateGiftReportsPriceRangeFilterEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    final normalized = _normalizePriceRange(event.minPrice, event.maxPrice);
    _minPriceFilter = normalized.$1;
    _maxPriceFilter = normalized.$2;
    _currentPage = 1;

    if (_catalogItems.isEmpty) {
      await _refreshCatalog(emit, page: 1, showLoading: false);
      return;
    }

    _emitFilteredPage(emit, page: 1);
  }

  (double?, double?) _normalizePriceRange(double? min, double? max) {
    if (min != null && max != null && min > max) {
      return (max, min);
    }
    return (min, max);
  }

  Future<void> _onChangeDays(
    ChangeGiftReportsDaysEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    _days = event.days;
    add(LoadGiftReportsOverviewEvent());
  }

  Future<void> _onRefresh(
    RefreshGiftReportsEvent event,
    Emitter<GiftReportsState> emit,
  ) async {
    add(LoadGiftReportsListEvent(page: _currentPage));
    add(LoadGiftReportsOverviewEvent());
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
