import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_history.dart';
import '../../domain/usecases/search_history_usecases.dart';
import 'search_history_event.dart';
import 'search_history_state.dart';

class SearchHistoryBloc extends Bloc<SearchHistoryEvent, SearchHistoryState> {
  SearchHistoryBloc({
    required GetSearchHistoryOverviewUseCase getOverview,
    required GetSearchHistoryUseCase getSearchHistory,
    required GetUserSearchHistoryUseCase getUserSearchHistory,
    required DeleteSearchHistoryUseCase deleteSearchHistory,
    required ClearSearchHistoryUseCase clearSearchHistory,
    required BulkSearchHistoryUseCase bulkSearchHistory,
  })  : _getOverview = getOverview,
        _getSearchHistory = getSearchHistory,
        _getUserSearchHistory = getUserSearchHistory,
        _deleteSearchHistory = deleteSearchHistory,
        _clearSearchHistory = clearSearchHistory,
        _bulkSearchHistory = bulkSearchHistory,
        super(SearchHistoryInitial()) {
    on<SetSearchHistoryScope>(_onSetScope);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<LoadUserSearchHistory>(_onLoadUserSearchHistory);
    on<UpdateFilters>(_onUpdateFilters);
    on<ClearFilters>(_onClearFilters);
    on<DeleteSearchHistoryItem>(_onDeleteItem);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<BulkDeleteSearchHistory>(_onBulkDelete);
    on<BulkClearUsersSearchHistory>(_onBulkClearUsers);
    on<ToggleSearchHistorySelection>(_onToggleSelection);
    on<SelectAllSearchHistory>(_onSelectAll);
    on<ClearSearchHistorySelection>(_onClearSelection);
  }

  final GetSearchHistoryOverviewUseCase _getOverview;
  final GetSearchHistoryUseCase _getSearchHistory;
  final GetUserSearchHistoryUseCase _getUserSearchHistory;
  final DeleteSearchHistoryUseCase _deleteSearchHistory;
  final ClearSearchHistoryUseCase _clearSearchHistory;
  final BulkSearchHistoryUseCase _bulkSearchHistory;

  SearchHistoryQuery _query = const SearchHistoryQuery();
  String? _scopedUserId;
  SearchHistoryOverviewEntity? _cachedOverview;

  void _onSetScope(
    SetSearchHistoryScope event,
    Emitter<SearchHistoryState> emit,
  ) {
    _scopedUserId = event.userId;
    _query = _query.copyWith(
      page: 1,
      userId: event.userId,
      clearUserId: event.userId == null,
    );
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    emit(SearchHistoryLoading());
    try {
      if (event.refreshOverview || _cachedOverview == null) {
        _cachedOverview = await _getOverview();
      }

      _query = _query.copyWith(page: event.page);
      final page = await _getSearchHistory(_query);

      emit(
        SearchHistoryLoaded(
          items: page.data,
          meta: page.meta,
          query: _query,
          overview: _cachedOverview,
          scopedUserId: _scopedUserId,
        ),
      );
    } catch (e) {
      emit(SearchHistoryError(e.toString()));
    }
  }

  Future<void> _onLoadUserSearchHistory(
    LoadUserSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    emit(SearchHistoryLoading());
    try {
      _scopedUserId = event.userId;
      _query = _query.copyWith(page: event.page, userId: event.userId);
      final page = await _getUserSearchHistory(
        userId: event.userId,
        query: _query,
      );

      emit(
        SearchHistoryLoaded(
          items: page.data,
          meta: page.meta,
          query: _query,
          scopedUserId: event.userId,
        ),
      );
    } catch (e) {
      emit(SearchHistoryError(e.toString()));
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<SearchHistoryState> emit,
  ) async {
    _query = _query.copyWith(
      page: 1,
      search: event.search,
      category: event.category,
      from: event.dateRange?.start,
      to: event.dateRange?.end,
      sort: event.sort,
      clearSearch: event.clearSearch,
      clearCategory: event.clearCategory,
      clearDateRange: event.clearDateRange,
    );

    if (_scopedUserId != null) {
      add(LoadUserSearchHistory(userId: _scopedUserId!));
    } else {
      add(const LoadSearchHistory(refreshOverview: false));
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<SearchHistoryState> emit,
  ) async {
    _query = SearchHistoryQuery(
      userId: _scopedUserId,
      limit: _query.limit,
      sort: _query.sort,
    );
    if (_scopedUserId != null) {
      add(LoadUserSearchHistory(userId: _scopedUserId!));
    } else {
      add(const LoadSearchHistory(refreshOverview: false));
    }
  }

  Future<void> _onDeleteItem(
    DeleteSearchHistoryItem event,
    Emitter<SearchHistoryState> emit,
  ) async {
    final current = state;
    if (current is! SearchHistoryLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _deleteSearchHistory(event.id);
      if (_scopedUserId != null) {
        add(LoadUserSearchHistory(userId: _scopedUserId!, page: _query.page));
      } else {
        add(LoadSearchHistory(page: _query.page, refreshOverview: true));
      }
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    final current = state;
    if (current is! SearchHistoryLoaded) return;
    final userId = event.userId ?? _scopedUserId;
    if (userId == null) return;

    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _clearSearchHistory(userId: userId, category: event.category);
      add(LoadUserSearchHistory(userId: userId));
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onBulkDelete(
    BulkDeleteSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    final current = state;
    if (current is! SearchHistoryLoaded || event.ids.isEmpty) return;

    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _bulkSearchHistory(
        SearchHistoryBulkRequest(
          action: SearchHistoryBulkAction.delete,
          searchHistoryIds: event.ids,
        ),
      );
      if (_scopedUserId != null) {
        add(LoadUserSearchHistory(userId: _scopedUserId!, page: _query.page));
      } else {
        add(LoadSearchHistory(page: _query.page, refreshOverview: true));
      }
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onBulkClearUsers(
    BulkClearUsersSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    final current = state;
    if (current is! SearchHistoryLoaded || event.userIds.isEmpty) return;

    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _bulkSearchHistory(
        SearchHistoryBulkRequest(
          action: SearchHistoryBulkAction.clearUsers,
          userIds: event.userIds,
          category: event.category,
        ),
      );
      add(LoadSearchHistory(page: _query.page, refreshOverview: true));
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ),
      );
    }
  }

  void _onToggleSelection(
    ToggleSearchHistorySelection event,
    Emitter<SearchHistoryState> emit,
  ) {
    final current = state;
    if (current is! SearchHistoryLoaded) return;

    final selected = Set<String>.from(current.selectedIds);
    if (selected.contains(event.id)) {
      selected.remove(event.id);
    } else {
      selected.add(event.id);
    }
    emit(current.copyWith(selectedIds: selected));
  }

  void _onSelectAll(
    SelectAllSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) {
    final current = state;
    if (current is! SearchHistoryLoaded) return;
    emit(
      current.copyWith(
        selectedIds: current.items.map((e) => e.id).toSet(),
      ),
    );
  }

  void _onClearSelection(
    ClearSearchHistorySelection event,
    Emitter<SearchHistoryState> emit,
  ) {
    final current = state;
    if (current is! SearchHistoryLoaded) return;
    emit(current.copyWith(selectedIds: const {}));
  }
}
