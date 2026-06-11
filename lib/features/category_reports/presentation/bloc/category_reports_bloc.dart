import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category_report_entities.dart';
import '../../domain/usecases/get_category_reports_list_usecase.dart';
import '../../domain/usecases/get_category_reports_overview_usecase.dart';

part 'category_reports_event.dart';
part 'category_reports_state.dart';

class CategoryReportsBloc
    extends Bloc<CategoryReportsEvent, CategoryReportsState> {
  CategoryReportsBloc({
    required GetCategoryReportsOverview getOverview,
    required GetCategoryReportsList getList,
  })  : _getOverview = getOverview,
        _getList = getList,
        super(CategoryReportsInitial()) {
    on<LoadCategoryReportsOverviewEvent>(_onLoadOverview);
    on<LoadCategoryReportsListEvent>(_onLoadList);
    on<GoToCategoryReportsPageEvent>(_onGoToPage);
    on<UpdateCategoryReportsSearchEvent>(_onUpdateSearch);
    on<UpdateCategoryReportsSortEvent>(_onUpdateSort);
    on<UpdateCategoryReportsActiveFilterEvent>(_onUpdateActiveFilter);
    on<UpdateCategoryReportsMainFilterEvent>(_onUpdateMainFilter);
    on<UpdateCategoryReportsParentFilterEvent>(_onUpdateParentFilter);
    on<ChangeCategoryReportsDaysEvent>(_onChangeDays);
    on<RefreshCategoryReportsEvent>(_onRefresh);
  }

  final GetCategoryReportsOverview _getOverview;
  final GetCategoryReportsList _getList;

  static const _pageLimit = 20;
  static const _searchDebounceMs = 300;

  Timer? _searchDebounce;
  bool _busy = false;
  bool _pendingListRefresh = false;
  int? _pendingListPage;

  int _currentPage = 1;
  int _days = 30;
  String _searchQuery = '';
  CategoryReportsSort _sort = CategoryReportsSort.newest;
  bool? _isActiveFilter;
  bool? _isMainFilter;
  String? _parentIdFilter;
  final List<CategoryReportFilterOption> _mainCategoryOptions = const [];

  CategoryReportPeriodQuery get _periodQuery =>
      CategoryReportPeriodQuery(days: _days);

  CategoryReportsListQuery get _listQuery => CategoryReportsListQuery(
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        isActive: _isActiveFilter,
        isMain: _isMainFilter,
        parentId: _parentIdFilter,
        sort: _sort,
      );

  CategoryReportsLoaded? get _loaded =>
      state is CategoryReportsLoaded ? state as CategoryReportsLoaded : null;

  Future<void> _onLoadOverview(
    LoadCategoryReportsOverviewEvent event,
    Emitter<CategoryReportsState> emit,
  ) async {
    final seed = _loaded ??
        CategoryReportsLoaded(
          items: const [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
          days: _days,
        );

    if (state is CategoryReportsLoaded) {
      emit(
        (state as CategoryReportsLoaded)
            .copyWith(isOverviewLoading: true, clearOverviewError: true),
      );
    } else if (state is! CategoryReportsLoading) {
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

  Future<void> _fetchListPage(
    Emitter<CategoryReportsState> emit, {
    required int page,
    bool showLoading = true,
  }) async {
    if (_busy) {
      _pendingListRefresh = true;
      _pendingListPage = page;
      return;
    }
    if (page < 1) return;

    _busy = true;
    final previous = state;
    if (showLoading && previous is! CategoryReportsLoaded) {
      emit(CategoryReportsLoading());
    } else if (previous is CategoryReportsLoaded) {
      emit(previous.copyWith(isListFetching: true, clearListError: true));
    }

    try {
      final response = await _getList(
        page: page,
        limit: _pageLimit,
        query: _listQuery,
      );

      _currentPage = response.page;

      final base = previous is CategoryReportsLoaded
          ? previous
          : CategoryReportsLoaded(
              items: const [],
              currentPage: 1,
              lastPage: 1,
              total: 0,
              days: _days,
            );

      emit(
        base.copyWith(
          items: response.items,
          currentPage: response.page,
          lastPage: response.lastPage,
          total: response.total,
          days: _days,
          searchQuery: _searchQuery,
          sort: _sort,
          isActiveFilter: _isActiveFilter,
          isMainFilter: _isMainFilter,
          parentIdFilter: _parentIdFilter,
          mainCategoryOptions: _mainCategoryOptions,
          isListFetching: false,
          clearListError: true,
        ),
      );
    } catch (e) {
      if (previous is CategoryReportsLoaded) {
        emit(
          previous.copyWith(
            isListFetching: false,
            listError: e.toString(),
          ),
        );
      } else {
        emit(CategoryReportsError(e.toString()));
      }
    } finally {
      _busy = false;
      if (_pendingListRefresh) {
        final pendingPage = _pendingListPage ?? page;
        _pendingListRefresh = false;
        _pendingListPage = null;
        add(LoadCategoryReportsListEvent(page: pendingPage));
      }
    }
  }

  Future<void> _onLoadList(
    LoadCategoryReportsListEvent event,
    Emitter<CategoryReportsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is CategoryReportsLoaded;
    await _fetchListPage(emit, page: page, showLoading: !hasData);
  }

  Future<void> _onGoToPage(
    GoToCategoryReportsPageEvent event,
    Emitter<CategoryReportsState> emit,
  ) async {
    await _fetchListPage(emit, page: event.page, showLoading: false);
  }

  void _onUpdateSearch(
    UpdateCategoryReportsSearchEvent event,
    Emitter<CategoryReportsState> emit,
  ) {
    _searchQuery = event.query;
    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      add(LoadCategoryReportsListEvent(refresh: true));
      return;
    }

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(LoadCategoryReportsListEvent(refresh: true)),
    );
  }

  void _onUpdateSort(
    UpdateCategoryReportsSortEvent event,
    Emitter<CategoryReportsState> emit,
  ) {
    _sort = event.sort;
    add(LoadCategoryReportsListEvent(refresh: true));
  }

  void _onUpdateActiveFilter(
    UpdateCategoryReportsActiveFilterEvent event,
    Emitter<CategoryReportsState> emit,
  ) {
    _isActiveFilter = event.isActive;
    add(LoadCategoryReportsListEvent(refresh: true));
  }

  void _onUpdateMainFilter(
    UpdateCategoryReportsMainFilterEvent event,
    Emitter<CategoryReportsState> emit,
  ) {
    _isMainFilter = event.isMain;
    if (event.isMain == true) {
      _parentIdFilter = null;
    }
    add(LoadCategoryReportsListEvent(refresh: true));
  }

  void _onUpdateParentFilter(
    UpdateCategoryReportsParentFilterEvent event,
    Emitter<CategoryReportsState> emit,
  ) {
    _parentIdFilter = event.parentId;
    if (event.parentId != null) {
      _isMainFilter = false;
    }
    add(LoadCategoryReportsListEvent(refresh: true));
  }

  Future<void> _onChangeDays(
    ChangeCategoryReportsDaysEvent event,
    Emitter<CategoryReportsState> emit,
  ) async {
    _days = event.days;
    add(LoadCategoryReportsOverviewEvent());
  }

  Future<void> _onRefresh(
    RefreshCategoryReportsEvent event,
    Emitter<CategoryReportsState> emit,
  ) async {
    add(LoadCategoryReportsListEvent(page: _currentPage));
    add(LoadCategoryReportsOverviewEvent());
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
