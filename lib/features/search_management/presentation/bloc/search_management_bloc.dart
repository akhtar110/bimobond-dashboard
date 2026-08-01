import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/search_debounce.dart';
import '../../domain/entities/search_management_entities.dart';
import '../../domain/usecases/search_management_usecases.dart';
import 'search_management_event.dart';
import 'search_management_state.dart';
import '../../../promotions/domain/entities/pagination_meta.dart';

class SearchManagementBloc
    extends Bloc<SearchManagementEvent, SearchManagementState> {
  SearchManagementBloc({
    required SearchUnifiedUseCase search,
    required GetSearchTrendsUseCase getTrends,
    required GetAdminSearchHistoryUseCase getAdminHistory,
    required GetSearchManagementOverviewUseCase getOverview,
    required SaveSearchHistoryUseCase saveHistory,
    required ClearMySearchHistoryUseCase clearHistory,
  })  : _search = search,
        _getTrends = getTrends,
        _getAdminHistory = getAdminHistory,
        _getOverview = getOverview,
        _saveHistory = saveHistory,
        _clearHistory = clearHistory,
        super(const SearchManagementInitial()) {
    on<LoadSearchManagementEvent>(_onLoad);
    on<RefreshSearchManagementEvent>(_onRefresh);
    on<SearchManagementQueryChangedEvent>(_onQueryChanged);
    on<SearchManagementCategoryChangedEvent>(_onCategoryChanged);
    on<SearchManagementUiTabChangedEvent>(_onUiTabChanged);
    on<SearchManagementDateChangedEvent>(_onDateChanged);
    on<SearchManagementSortChangedEvent>(_onSortChanged);
    on<SearchManagementTrendingFilterChangedEvent>(_onTrendingChanged);
    on<SearchManagementFilterAppliedEvent>(_onFilterApplied);
    on<SearchManagementFilterResetEvent>(_onFilterReset);
    on<SearchManagementLoadNextPageEvent>(_onLoadNextPage);
    on<SearchManagementPageChangedEvent>(_onPageChanged);
    on<SearchManagementOpenDetailsEvent>(_onOpenDetails);
    on<SearchManagementSaveHistoryEvent>(_onSaveHistory);
    on<SearchManagementClearHistoryEvent>(_onClearHistory);
  }

  final SearchUnifiedUseCase _search;
  final GetSearchTrendsUseCase _getTrends;
  final GetAdminSearchHistoryUseCase _getAdminHistory;
  final GetSearchManagementOverviewUseCase _getOverview;
  final SaveSearchHistoryUseCase _saveHistory;
  final ClearMySearchHistoryUseCase _clearHistory;

  SearchManagementFilterQuery _filter = const SearchManagementFilterQuery();
  SearchManagementTab _uiTab = SearchManagementTab.overview;
  final SearchRequestGuard _reloadGuard = SearchRequestGuard();

  Future<void> _onLoad(
    LoadSearchManagementEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    emit(const SearchManagementLoading());
    await _reloadAll(emit, refreshing: false);
  }

  Future<void> _onRefresh(
    RefreshSearchManagementEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    final current = state;
    if (current is SearchManagementLoaded) {
      emit(current.copyWith(isRefreshing: true, clearMessage: true));
    } else {
      emit(const SearchManagementLoading());
    }
    await _reloadAll(emit, refreshing: true);
  }

  Future<void> _onQueryChanged(
    SearchManagementQueryChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _filter = _filter.copyWith(q: event.query, page: 1);
    await _reloadContent(emit);
  }

  Future<void> _onCategoryChanged(
    SearchManagementCategoryChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _filter = _filter.copyWith(apiTab: event.apiTab, page: 1);
    await _reloadContent(emit);
  }

  Future<void> _onUiTabChanged(
    SearchManagementUiTabChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _uiTab = event.tab;
    _filter = _filter.copyWith(
      apiTab: _apiTabForUi(event.tab),
      page: 1,
    );
    await _reloadContent(emit);
  }

  Future<void> _onDateChanged(
    SearchManagementDateChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    if (event.clear) {
      _filter = _filter.copyWith(clearDateRange: true, page: 1);
    } else {
      _filter = _filter.copyWith(from: event.from, to: event.to, page: 1);
    }
    await _reloadContent(emit);
  }

  Future<void> _onSortChanged(
    SearchManagementSortChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _filter = _filter.copyWith(sort: event.sort, page: 1);
    await _reloadContent(emit);
  }

  Future<void> _onTrendingChanged(
    SearchManagementTrendingFilterChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _filter = _filter.copyWith(trendingOnly: event.trendingOnly, page: 1);
    await _reloadContent(emit);
  }

  Future<void> _onFilterApplied(
    SearchManagementFilterAppliedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    if (event.filter != null) {
      final next = event.filter!;
      _filter = SearchManagementFilterQuery(
        q: _filter.q,
        apiTab: next.apiTab,
        page: 1,
        limit: next.limit,
        from: next.from,
        to: next.to,
        sort: next.sort,
        trendingOnly: next.trendingOnly,
      );
      await _reloadContent(emit);
      return;
    }
    _filter = _filter.copyWith(page: 1);
    await _reloadAll(emit, refreshing: true);
  }

  Future<void> _onFilterReset(
    SearchManagementFilterResetEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    _filter = const SearchManagementFilterQuery();
    await _reloadAll(emit, refreshing: true);
  }

  Future<void> _onLoadNextPage(
    SearchManagementLoadNextPageEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    final current = state;
    if (current is! SearchManagementLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = _filter.page + 1;
      _filter = _filter.copyWith(page: nextPage);

      if (_uiTab == SearchManagementTab.searches) {
        final more = await _getAdminHistory(
          search: _filter.q.trim().isEmpty ? null : _filter.q.trim(),
          category: _historyCategoryForApi(_filter.apiTab),
          from: _filter.from,
          to: _filter.to,
          page: nextPage,
        );
        emit(
          current.copyWith(
            filter: _filter,
            history: SearchHistoryPageResult(
              data: [...current.history.data, ...more.data],
              meta: more.meta,
            ),
            isLoadingMore: false,
          ),
        );
        return;
      }

      final more = await _search(_filter);
      emit(
        current.copyWith(
          filter: _filter,
          searchResult: _mergeSearch(current.searchResult, more),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      _filter = _filter.copyWith(page: (_filter.page - 1).clamp(1, 9999));
      emit(
        current.copyWith(
          isLoadingMore: false,
          message: e.toString().replaceFirst('Exception: ', ''),
          isErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onPageChanged(
    SearchManagementPageChangedEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    final page = event.page;
    if (page < 1 || page == _filter.page) return;
    _filter = _filter.copyWith(page: page);
    await _reloadContent(emit);
  }

  void _onOpenDetails(
    SearchManagementOpenDetailsEvent event,
    Emitter<SearchManagementState> emit,
  ) {
    final current = state;
    if (current is SearchManagementLoaded) {
      emit(current.copyWith(detailsPayload: event.payload));
    }
  }

  Future<void> _onSaveHistory(
    SearchManagementSaveHistoryEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    final q = _filter.q.trim();
    if (q.isEmpty) return;
    try {
      await _saveHistory(
        query: q,
        category: _filter.apiTab.apiValue,
      );
      final current = state;
      if (current is SearchManagementLoaded) {
        emit(
          current.copyWith(
            message: 'Search saved to history',
            isErrorMessage: false,
          ),
        );
      }
    } catch (e) {
      final current = state;
      if (current is SearchManagementLoaded) {
        emit(
          current.copyWith(
            message: e.toString().replaceFirst('Exception: ', ''),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onClearHistory(
    SearchManagementClearHistoryEvent event,
    Emitter<SearchManagementState> emit,
  ) async {
    try {
      await _clearHistory(category: event.category);
      await _reloadContent(emit);
      final current = state;
      if (current is SearchManagementLoaded) {
        emit(
          current.copyWith(
            message: 'Search history cleared',
            isErrorMessage: false,
          ),
        );
      }
    } catch (e) {
      final current = state;
      if (current is SearchManagementLoaded) {
        emit(
          current.copyWith(
            message: e.toString().replaceFirst('Exception: ', ''),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _reloadAll(
    Emitter<SearchManagementState> emit, {
    required bool refreshing,
  }) async {
    try {
      final overview = await _getOverview(
        seedQuery: _filter.q.trim().isEmpty ? 'a' : _filter.q.trim(),
      );
      final bundle = await _fetchBundle();
      _emitBundle(emit, overview: overview, bundle: bundle);
    } catch (e) {
      emit(SearchManagementError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _reloadContent(Emitter<SearchManagementState> emit) async {
    final token = _reloadGuard.next();
    final current = state;
    final previous = current is SearchManagementLoaded ? current : null;
    final overview = previous?.overview ??
        const SearchManagementOverviewEntity(
          totalSearches: 0,
          totalUsers: 0,
          totalPosts: 0,
          totalSounds: 0,
          totalHashtags: 0,
          trendingCount: 0,
        );

    if (previous != null) {
      emit(previous.copyWith(isRefreshing: true, clearMessage: true));
    } else {
      emit(const SearchManagementLoading());
    }

    try {
      final bundle = await _fetchBundle(previous: previous);
      if (!_reloadGuard.isCurrent(token)) return;
      _emitBundle(emit, overview: overview, bundle: bundle);
    } catch (e) {
      if (!_reloadGuard.isCurrent(token)) return;
      emit(SearchManagementError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<
      ({
        UnifiedSearchResult search,
        List<SearchTrendEntity> trends,
        SearchHistoryPageResult history,
      })> _fetchBundle({SearchManagementLoaded? previous}) async {
    final q = _filter.q.trim().isEmpty ? null : _filter.q.trim();

    var search = previous?.searchResult ??
        UnifiedSearchResult(q: _filter.q, tab: _apiTabForUi(_uiTab));
    var trends = previous?.trends ?? const <SearchTrendEntity>[];
    var history = previous?.history ??
        const SearchHistoryPageResult(
          data: [],
          meta: PaginationMeta(
            total: 0,
            page: 1,
            limit: 20,
            totalPages: 1,
          ),
        );

    switch (_uiTab) {
      case SearchManagementTab.overview:
        final results = await Future.wait([
          _search(_filter.copyWith(apiTab: _apiTabForUi(_uiTab))),
          _getTrends(search: q),
          _getAdminHistory(
            search: q,
            category: _historyCategoryForApi(_filter.apiTab),
            from: _filter.from,
            to: _filter.to,
            page: _filter.page,
          ),
        ]);
        search = results[0] as UnifiedSearchResult;
        trends = results[1] as List<SearchTrendEntity>;
        history = results[2] as SearchHistoryPageResult;
      case SearchManagementTab.searches:
        history = await _getAdminHistory(
          search: q,
          category: _historyCategoryForApi(_filter.apiTab),
          from: _filter.from,
          to: _filter.to,
          page: _filter.page,
        );
      case SearchManagementTab.users:
      case SearchManagementTab.sounds:
      case SearchManagementTab.hashtags:
        search = await _search(
          _filter.copyWith(apiTab: _apiTabForUi(_uiTab)),
        );
      case SearchManagementTab.trends:
        trends = await _getTrends(search: q);
    }

    return (search: search, trends: trends, history: history);
  }

  void _emitBundle(
    Emitter<SearchManagementState> emit, {
    required SearchManagementOverviewEntity overview,
    required ({
      UnifiedSearchResult search,
      List<SearchTrendEntity> trends,
      SearchHistoryPageResult history,
    }) bundle,
  }) {
    var trends = bundle.trends;
    if (_filter.trendingOnly) {
      trends = trends.where((t) => t.count > 0 || (t.score ?? 0) > 0).toList();
    }

    final isEmpty = switch (_uiTab) {
      SearchManagementTab.overview => false,
      SearchManagementTab.searches => bundle.history.data.isEmpty,
      SearchManagementTab.users => (bundle.search.users?.data ?? const []).isEmpty,
      SearchManagementTab.sounds =>
        (bundle.search.sounds?.data ?? const []).isEmpty,
      SearchManagementTab.hashtags =>
        (bundle.search.hashtags?.data ?? const []).isEmpty,
      SearchManagementTab.trends => trends.isEmpty,
    };

    if (isEmpty &&
        _uiTab != SearchManagementTab.overview &&
        !(_filter.q.trim().isEmpty && _uiTab == SearchManagementTab.searches)) {
      // Still emit loaded with empty lists for consistent UI; Empty UI handled in widgets.
    }

    emit(
      SearchManagementLoaded(
        filter: _filter,
        uiTab: _uiTab,
        overview: overview,
        searchResult: bundle.search,
        trends: trends,
        history: bundle.history,
      ),
    );
  }

  SearchApiTab _apiTabForUi(SearchManagementTab tab) {
    return switch (tab) {
      SearchManagementTab.overview => SearchApiTab.best,
      SearchManagementTab.searches => SearchApiTab.posts,
      SearchManagementTab.users => SearchApiTab.users,
      SearchManagementTab.sounds => SearchApiTab.sounds,
      SearchManagementTab.hashtags => SearchApiTab.hashtags,
      SearchManagementTab.trends => _filter.apiTab,
    };
  }

  String? _historyCategoryForApi(SearchApiTab tab) {
    return switch (tab) {
      SearchApiTab.best => null,
      SearchApiTab.posts => 'POSTS',
      SearchApiTab.users => 'USERS',
      SearchApiTab.sounds => 'SOUNDS',
      SearchApiTab.hashtags => 'HASHTAGS',
    };
  }

  UnifiedSearchResult _mergeSearch(
    UnifiedSearchResult current,
    UnifiedSearchResult more,
  ) {
    return UnifiedSearchResult(
      q: more.q,
      tab: more.tab,
      posts: _mergeSection(current.posts, more.posts),
      users: _mergeSection(current.users, more.users),
      sounds: _mergeSection(current.sounds, more.sounds),
      hashtags: _mergeSection(current.hashtags, more.hashtags),
    );
  }

  SearchSection<T>? _mergeSection<T>(
    SearchSection<T>? current,
    SearchSection<T>? more,
  ) {
    if (more == null) return current;
    if (current == null) return more;
    return SearchSection(
      data: [...current.data, ...more.data],
      meta: more.meta,
    );
  }
}
