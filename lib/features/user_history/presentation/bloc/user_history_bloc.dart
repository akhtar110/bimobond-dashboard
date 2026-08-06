import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../domain/entities/user_history_entity.dart';
import '../../domain/usecases/get_user_history_usecase.dart';
import 'user_history_event.dart';
import 'user_history_state.dart';

class UserHistoryBloc extends Bloc<UserHistoryEvent, UserHistoryState> {
  UserHistoryBloc({required GetUserHistoryUseCase getUserHistory})
      : _getUserHistory = getUserHistory,
        super(const UserHistoryInitial()) {
    on<SetUserHistoryUserId>(_onSetUserId);
    on<LoadUserHistory>(_onLoad);
    on<RefreshUserHistory>(_onRefresh);
    on<LoadNextUserHistoryPage>(_onLoadNext);
    on<ChangeUserHistoryPage>(_onChangePage);
    on<ChangeUserHistoryFilters>(_onChangeFilters);
    on<ClearUserHistoryFilters>(_onClearFilters);
    on<StartRealtimeUserHistoryListening>(_onStartRealtimeListening);
    on<StopRealtimeUserHistoryListening>(_onStopRealtimeListening);
    on<PollRealtimeUserHistory>(_onPollRealtime);
  }

  final GetUserHistoryUseCase _getUserHistory;

  UserHistoryQuery _query = const UserHistoryQuery();
  String _userId = '';
  Timer? _realtimeTimer;
  bool _isRealtimeActive = false;

  bool get isRealtimeActive => _isRealtimeActive;

  @override
  Future<void> close() {
    _realtimeTimer?.cancel();
    return super.close();
  }

  void _onSetUserId(
    SetUserHistoryUserId event,
    Emitter<UserHistoryState> emit,
  ) {
    _userId = event.userId;
    emit(
      UserHistoryInitial(
        userId: _userId,
        query: _query,
        hasLoadedOnce: state.hasLoadedOnce,
      ),
    );
  }

  Future<void> _onStartRealtimeListening(
    StartRealtimeUserHistoryListening event,
    Emitter<UserHistoryState> emit,
  ) async {
    _realtimeTimer?.cancel();
    _isRealtimeActive = true;
    _realtimeTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds.clamp(3, 60)),
      (_) {
        if (!isClosed && _userId.isNotEmpty) {
          add(const PollRealtimeUserHistory());
        }
      },
    );
  }

  Future<void> _onStopRealtimeListening(
    StopRealtimeUserHistoryListening event,
    Emitter<UserHistoryState> emit,
  ) async {
    _realtimeTimer?.cancel();
    _isRealtimeActive = false;
  }

  Future<void> _onPollRealtime(
    PollRealtimeUserHistory event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty || _query.page != 1) return;
    try {
      final page = await _getUserHistory(
        userId: _userId,
        query: _query,
      );

      final filtered = page.items;
      final currentItems = _currentItems();

      // Detect if timeline has changed
      if (filtered.isNotEmpty) {
        final hasChanges = currentItems.length != filtered.length ||
            (currentItems.isNotEmpty &&
                filtered.isNotEmpty &&
                (currentItems.first.createdAt != filtered.first.createdAt ||
                    currentItems.first.type != filtered.first.type));

        if (hasChanges) {
          emit(
            UserHistoryLoaded(
              userId: _userId,
              query: _query,
              items: filtered,
              meta: page.meta,
            ),
          );
        }
      }
    } catch (_) {
      // Silent error handling for background realtime polling
    }
  }

  Future<void> _onLoad(
    LoadUserHistory event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;

    if (event.page != null) {
      _query = _query.copyWith(page: event.page);
    }

    await _fetch(
      emit,
      showFullLoading: !state.hasLoadedOnce || _currentItems().isEmpty,
    );
  }

  Future<void> _onRefresh(
    RefreshUserHistory event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;
    _query = _query.copyWith(page: 1);
    await _fetch(emit, showFullLoading: true);
  }

  Future<void> _onLoadNext(
    LoadNextUserHistoryPage event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;
    final meta = _currentMeta();
    if (meta == null || meta.hasReachedMax) return;
    _query = _query.copyWith(page: meta.page + 1);
    await _fetch(emit, showFullLoading: false);
  }

  Future<void> _onChangePage(
    ChangeUserHistoryPage event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;
    if (event.page < 1) return;
    _query = _query.copyWith(page: event.page);
    await _fetch(emit, showFullLoading: false);
  }

  Future<void> _onChangeFilters(
    ChangeUserHistoryFilters event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;

    _query = _query.copyWith(
      page: 1,
      from: event.dateRange?.start,
      to: event.dateRange?.end,
      types: event.types,
      clearDateRange: event.clearDateRange,
      clearTypes: event.clearTypes,
    );

    await _fetch(emit, showFullLoading: true);
  }

  Future<void> _onClearFilters(
    ClearUserHistoryFilters event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (_userId.isEmpty) return;
    _query = UserHistoryQuery(limit: _query.limit);
    await _fetch(emit, showFullLoading: true);
  }

  Future<void> _fetch(
    Emitter<UserHistoryState> emit, {
    required bool showFullLoading,
  }) async {
    final previousItems = _currentItems();
    final previousMeta = _currentMeta();

    if (showFullLoading) {
      emit(
        UserHistoryLoading(
          userId: _userId,
          query: _query,
          hasLoadedOnce: state.hasLoadedOnce,
        ),
      );
    } else if (previousMeta != null) {
      emit(
        UserHistoryLoadingMore(
          userId: _userId,
          query: _query,
          items: previousItems,
          meta: previousMeta,
        ),
      );
    } else {
      emit(
        UserHistoryLoading(
          userId: _userId,
          query: _query,
          hasLoadedOnce: state.hasLoadedOnce,
        ),
      );
    }

    try {
      final page = await _getUserHistory(
        userId: _userId,
        query: _query,
      );

      if (page.items.isEmpty) {
        emit(
          UserHistoryEmpty(
            userId: _userId,
            query: _query,
            meta: page.meta,
          ),
        );
        return;
      }

      emit(
        UserHistoryLoaded(
          userId: _userId,
          query: _query,
          items: page.items,
          meta: page.meta,
        ),
      );
    } catch (e) {
      emit(
        UserHistoryError(
          userId: _userId,
          query: _query,
          message: ApiErrorMessages.from(e),
          items: previousItems,
          meta: previousMeta,
          hasLoadedOnce: state.hasLoadedOnce,
        ),
      );
    }
  }

  List<UserHistoryEntity> _currentItems() {
    final current = state;
    return switch (current) {
      UserHistoryLoaded(:final items) => items,
      UserHistoryLoadingMore(:final items) => items,
      UserHistoryError(:final items) => items,
      _ => const [],
    };
  }

  UserHistoryMetaEntity? _currentMeta() {
    final current = state;
    return switch (current) {
      UserHistoryLoaded(:final meta) => meta,
      UserHistoryEmpty(:final meta) => meta,
      UserHistoryLoadingMore(:final meta) => meta,
      UserHistoryError(:final meta) => meta,
      _ => null,
    };
  }
}
