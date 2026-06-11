import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_report_entities.dart';
import '../../domain/usecases/get_user_report_detail.dart';
import '../../domain/usecases/get_user_reports_list.dart';
import '../../domain/usecases/get_user_reports_overview.dart';

part 'user_reports_event.dart';
part 'user_reports_state.dart';

class UserReportsBloc extends Bloc<UserReportsEvent, UserReportsState> {
  UserReportsBloc({
    required GetUserReportsOverview getOverview,
    required GetUserReportsList getList,
    required GetUserReportDetail getDetail,
  })  : _getOverview = getOverview,
        _getList = getList,
        _getDetail = getDetail,
        super(const UserReportsInitial()) {
    on<LoadOverview>(_onLoadOverview);
    on<LoadList>(_onLoadList);
    on<LoadMore>(_onLoadMore);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
    on<GoToPage>(_onGoToPage);
    on<LoadDetail>(_onLoadDetail);
  }

  final GetUserReportsOverview _getOverview;
  final GetUserReportsList _getList;
  final GetUserReportDetail _getDetail;

  static const _pageLimit = 20;
  static const _searchDebounceMs = 400;

  Timer? _searchDebounce;
  bool _listBusy = false;

  UserReportListQuery _query = const UserReportListQuery();
  final List<UserReportListItemEntity> _items = [];

  UserReportsLoaded? get _loaded =>
      state is UserReportsLoaded ? state as UserReportsLoaded : null;

  UserReportsLoaded _baseLoaded() =>
      _loaded ??
      UserReportsLoaded(
        query: _query,
        items: List.of(_items),
        currentPage: _query.page,
      );

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onLoadOverview(
    LoadOverview event,
    Emitter<UserReportsState> emit,
  ) async {
    final base = _baseLoaded();
    emit(
      base.copyWith(
        overviewLoading: true,
        overviewDays: event.days,
        clearOverviewError: true,
      ),
    );

    try {
      final overview = await _getOverview(days: event.days);
      emit(
        _baseLoaded().copyWith(
          overview: overview,
          overviewLoading: false,
          overviewDays: event.days,
          clearOverviewError: true,
        ),
      );
    } catch (e) {
      emit(
        _baseLoaded().copyWith(
          overviewLoading: false,
          overviewError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadList(
    LoadList event,
    Emitter<UserReportsState> emit,
  ) async {
    if (event.refresh) {
      _query = _query.copyWith(page: 1);
    }
    await _fetchListPage(emit, page: _query.page, replace: true);
  }

  Future<void> _onLoadMore(
    LoadMore event,
    Emitter<UserReportsState> emit,
  ) async {
    final loaded = _loaded;
    if (loaded != null && loaded.hasReachedMax) return;
    final nextPage = (_loaded?.currentPage ?? _query.page) + 1;
    await _fetchListPage(emit, page: nextPage, replace: false);
  }

  Future<void> _onGoToPage(
    GoToPage event,
    Emitter<UserReportsState> emit,
  ) async {
    if (event.page < 1) return;
    _query = _query.copyWith(page: event.page);
    await _fetchListPage(emit, page: event.page, replace: true);
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<UserReportsState> emit,
  ) {
    _query = _query.copyWith(page: 1, search: event.query);
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(const LoadList(refresh: true)),
    );
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<UserReportsState> emit,
  ) async {
    _query = _query.copyWith(
      page: 1,
      isVerified: event.isVerified,
      isBanned: event.isBanned,
      role: event.role,
      clearVerified: event.clearVerified,
      clearBanned: event.clearBanned,
      clearRole: event.clearRole,
    );
    await _fetchListPage(emit, page: 1, replace: true);
  }

  Future<void> _onSortChanged(
    SortChanged event,
    Emitter<UserReportsState> emit,
  ) async {
    _query = _query.copyWith(page: 1, sort: event.sort);
    await _fetchListPage(emit, page: 1, replace: true);
  }

  Future<void> _fetchListPage(
    Emitter<UserReportsState> emit, {
    required int page,
    required bool replace,
  }) async {
    if (_listBusy) return;
    if (page < 1) return;

    _listBusy = true;
    _query = _query.copyWith(page: page, limit: _pageLimit);

    final previous = _loaded;
    if (previous == null || replace) {
      emit(UserReportsLoading(previous: previous));
    } else {
      emit(previous.copyWith(listLoadingMore: true, clearListError: true));
    }

    try {
      final response = await _getList(_query);

      if (replace) {
        _items
          ..clear()
          ..addAll(response.items);
      } else {
        _items.addAll(response.items);
      }

      _query = _query.copyWith(page: response.page);

      emit(
        UserReportsLoaded(
          query: _query,
          overview: previous?.overview,
          overviewLoading: previous?.overviewLoading ?? false,
          overviewError: previous?.overviewError,
          overviewDays: previous?.overviewDays ?? 30,
          items: List.of(_items),
          currentPage: response.page,
          lastPage: response.lastPage,
          total: response.total,
          listLoading: false,
          listLoadingMore: false,
          detail: previous?.detail,
          detailUserId: previous?.detailUserId,
          detailLoading: previous?.detailLoading ?? false,
          detailError: previous?.detailError,
          detailDays: previous?.detailDays ?? 30,
        ),
      );
    } catch (e) {
      if (previous != null && !replace) {
        emit(
          previous.copyWith(
            listLoadingMore: false,
            listError: e.toString(),
          ),
        );
      } else {
        emit(UserReportsError(e.toString()));
      }
    } finally {
      _listBusy = false;
    }
  }

  Future<void> _onLoadDetail(
    LoadDetail event,
    Emitter<UserReportsState> emit,
  ) async {
    final base = _baseLoaded();
    emit(
      base.copyWith(
        detailUserId: event.userId,
        detailDays: event.days,
        detailLoading: true,
        clearDetailError: true,
        clearDetail: true,
      ),
    );

    try {
      final detail = await _getDetail(event.userId, days: event.days);
      emit(
        _baseLoaded().copyWith(
          detail: detail,
          detailUserId: event.userId,
          detailDays: event.days,
          detailLoading: false,
          clearDetailError: true,
        ),
      );
    } catch (e) {
      emit(
        _baseLoaded().copyWith(
          detailUserId: event.userId,
          detailDays: event.days,
          detailLoading: false,
          detailError: e.toString(),
        ),
      );
    }
  }
}
