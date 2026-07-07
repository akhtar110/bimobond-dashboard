import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post_report_entities.dart';
import '../../domain/entities/post_reports_query.dart';
import '../../domain/usecases/get_post_reports_list.dart';
import '../../domain/usecases/get_post_reports_overview.dart';

part 'post_reports_event.dart';
part 'post_reports_state.dart';

class PostReportsBloc extends Bloc<PostReportsEvent, PostReportsState> {
  PostReportsBloc({
    required GetPostReportsList getPostReportsList,
    required GetPostReportsOverview getPostReportsOverview,
  })  : _getPostReportsList = getPostReportsList,
        _getPostReportsOverview = getPostReportsOverview,
        super(PostReportsInitial()) {
    on<LoadPostReportsEvent>(_onLoad);
    on<GoToPostReportsPageEvent>(_onGoToPage);
    on<LoadMorePostReportsEvent>(_onLoadMore);
    on<UpdatePostReportsSearchEvent>(_onUpdateSearch);
    on<UpdatePostReportsFiltersEvent>(_onUpdateFilters);
    on<UpdatePostReportsSortEvent>(_onUpdateSort);
    on<ClearPostReportsFiltersEvent>(_onClearFilters);
    on<LoadPostReportsOverviewEvent>(_onLoadOverview);
  }

  final GetPostReportsList _getPostReportsList;
  final GetPostReportsOverview _getPostReportsOverview;

  static const _pageLimit = 20;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  bool _busy = false;

  PostReportsListQuery _query = const PostReportsListQuery();
  String _searchQuery = '';
  int _currentPage = 1;
  int _overviewDays = 30;

  Future<void> _fetchPage(
    Emitter<PostReportsState> emit, {
    required int page,
    required bool replace,
    bool showLoading = true,
  }) async {
    if (_busy) return;
    if (page < 1) return;

    _busy = true;
    final previous = state;
    if (showLoading && previous is! PostReportsLoaded) {
      emit(PostReportsLoading());
    } else if (previous is PostReportsLoaded) {
      emit(
        replace
            ? previous.copyWith(isFetching: true, isLoadingMore: false)
            : previous.copyWith(isLoadingMore: true),
      );
    }

    try {
      final response = await _getPostReportsList(
        page: page,
        limit: _pageLimit,
        query: _query,
      );

      _currentPage = response.page;

      final merged = replace
          ? response.items
          : <PostReportListItem>[
              if (previous is PostReportsLoaded) ...previous.posts,
              ...response.items,
            ];

      emit(PostReportsLoaded(
        posts: merged,
        currentPage: response.page,
        lastPage: response.lastPage,
        total: response.total,
        query: _query,
        searchQuery: _searchQuery,
        isFetching: false,
        isLoadingMore: false,
        overview: previous is PostReportsLoaded ? previous.overview : null,
        overviewDays: _overviewDays,
      ));
    } catch (e) {
      if (previous is PostReportsLoaded) {
        emit(
          previous.copyWith(
            isFetching: false,
            isLoadingMore: false,
          ),
        );
      } else {
        emit(PostReportsError(e.toString()));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onLoad(
    LoadPostReportsEvent event,
    Emitter<PostReportsState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is PostReportsLoaded;
    await _fetchPage(
      emit,
      page: page,
      replace: true,
      showLoading: !hasData,
    );
  }

  Future<void> _onGoToPage(
    GoToPostReportsPageEvent event,
    Emitter<PostReportsState> emit,
  ) async {
    await _fetchPage(
      emit,
      page: event.page,
      replace: true,
      showLoading: false,
    );
  }

  Future<void> _onLoadMore(
    LoadMorePostReportsEvent event,
    Emitter<PostReportsState> emit,
  ) async {
    final loaded = state;
    if (loaded is! PostReportsLoaded) return;
    if (loaded.hasReachedMax || loaded.isLoadingMore || loaded.isFetching) {
      return;
    }
    await _fetchPage(
      emit,
      page: loaded.currentPage + 1,
      replace: false,
      showLoading: false,
    );
  }

  void _onUpdateSearch(
    UpdatePostReportsSearchEvent event,
    Emitter<PostReportsState> emit,
  ) {
    _searchQuery = event.query;
    _query = _query.copyWith(
      search: event.query.trim().isEmpty ? null : event.query.trim(),
      clearSearch: event.query.trim().isEmpty,
    );

    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      add(LoadPostReportsEvent(refresh: true));
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(LoadPostReportsEvent(refresh: true)),
    );
  }

  void _onUpdateFilters(
    UpdatePostReportsFiltersEvent event,
    Emitter<PostReportsState> emit,
  ) {
    _query = event.query;
    add(LoadPostReportsEvent(refresh: true));
  }

  void _onUpdateSort(
    UpdatePostReportsSortEvent event,
    Emitter<PostReportsState> emit,
  ) {
    _query = _query.copyWith(sort: event.sort);
    add(LoadPostReportsEvent(refresh: true));
  }

  void _onClearFilters(
    ClearPostReportsFiltersEvent event,
    Emitter<PostReportsState> emit,
  ) {
    _searchQuery = '';
    _query = const PostReportsListQuery();
    add(LoadPostReportsEvent(refresh: true));
  }

  Future<void> _onLoadOverview(
    LoadPostReportsOverviewEvent event,
    Emitter<PostReportsState> emit,
  ) async {
    _overviewDays = event.days;
    final current = state;
    if (current is PostReportsLoaded) {
      emit(current.copyWith(isOverviewLoading: true));
    }

    try {
      final overview = await _getPostReportsOverview(
        ReportPeriodQuery(days: event.days),
      );
      final loaded = state;
      if (loaded is PostReportsLoaded) {
        emit(loaded.copyWith(
          overview: overview,
          isOverviewLoading: false,
          overviewDays: event.days,
        ));
      } else {
        emit(PostReportsLoaded(
          posts: const [],
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
      if (loaded is PostReportsLoaded) {
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
