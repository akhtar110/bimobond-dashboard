import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_filters.dart';
import '../../domain/usecases/notifications_usecases.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class UserNotificationsEvent {}

class LoadUserNotifications extends UserNotificationsEvent {
  LoadUserNotifications({required this.userId});
  final String userId;
}

class RefreshUserNotifications extends UserNotificationsEvent {
  RefreshUserNotifications({required this.userId});
  final String userId;
}

class LoadMoreUserNotifications extends UserNotificationsEvent {
  LoadMoreUserNotifications({required this.userId});
  final String userId;
}

// ─── State ────────────────────────────────────────────────────────────────────

class UserNotificationsState {
  const UserNotificationsState({
    this.userId = '',
    this.notifications = const [],
    this.page = 0,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.hasReachedMax = false,
    this.error,
    this.loaded = false,
  });

  final String userId;
  final List<NotificationEntity> notifications;
  final int page;
  final int total;
  final bool loading;
  final bool loadingMore;
  final bool hasReachedMax;
  final String? error;
  final bool loaded;

  UserNotificationsState copyWith({
    String? userId,
    List<NotificationEntity>? notifications,
    int? page,
    int? total,
    bool? loading,
    bool? loadingMore,
    bool? hasReachedMax,
    String? error,
    bool clearError = false,
    bool? loaded,
  }) {
    return UserNotificationsState(
      userId: userId ?? this.userId,
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: clearError ? null : (error ?? this.error),
      loaded: loaded ?? this.loaded,
    );
  }
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UserNotificationsBloc
    extends Bloc<UserNotificationsEvent, UserNotificationsState> {
  UserNotificationsBloc({required GetAllNotifications getAllNotifications})
      : _getAll = getAllNotifications,
        super(const UserNotificationsState()) {
    on<LoadUserNotifications>(_onLoad);
    on<RefreshUserNotifications>(_onRefresh);
    on<LoadMoreUserNotifications>(_onLoadMore);
  }

  final GetAllNotifications _getAll;
  static const int _limit = 20;

  Future<void> _onLoad(
    LoadUserNotifications event,
    Emitter<UserNotificationsState> emit,
  ) async {
    emit(state.copyWith(
      userId: event.userId,
      loading: true,
      notifications: [],
      page: 0,
      hasReachedMax: false,
      loaded: true,
      clearError: true,
    ));
    await _fetch(event.userId, 1, emit, replace: true);
  }

  Future<void> _onRefresh(
    RefreshUserNotifications event,
    Emitter<UserNotificationsState> emit,
  ) async {
    emit(state.copyWith(
      loading: true,
      notifications: [],
      page: 0,
      hasReachedMax: false,
      clearError: true,
    ));
    await _fetch(event.userId, 1, emit, replace: true);
  }

  Future<void> _onLoadMore(
    LoadMoreUserNotifications event,
    Emitter<UserNotificationsState> emit,
  ) async {
    if (state.hasReachedMax || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(event.userId, state.page + 1, emit, replace: false);
  }

  Future<void> _fetch(
    String userId,
    int page,
    Emitter<UserNotificationsState> emit, {
    required bool replace,
  }) async {
    try {
      final result = await _getAll(
        page: page,
        limit: _limit,
        filters: NotificationFilters(userId: userId),
      );
      final newList = replace
          ? result.notifications
          : [...state.notifications, ...result.notifications];
      emit(state.copyWith(
        notifications: newList,
        page: result.page,
        total: result.total,
        hasReachedMax: result.page >= result.lastPage,
        loading: false,
        loadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
