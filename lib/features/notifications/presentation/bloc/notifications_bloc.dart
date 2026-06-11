import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/users/domain/entities/user_entity.dart';
import '../../../../features/users/domain/usecases/get_users.dart';
import '../../domain/entities/admin_notification_event_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_filters.dart';
import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_send_result_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/notifications_usecases.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc
    extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this.sendNotification,
    required this.sendBulkNotification,
    required this.broadcastNotification,
    required this.broadcastAdminsNotification,
    required this.repository,
    required this.getUsers,
    required this.getAllNotifications,
  }) : super(const NotificationsState()) {
    on<ConnectAdminSocket>(_onConnect);
    on<DisconnectAdminSocket>(_onDisconnect);
    on<AdminNotificationReceived>(_onAdminNotificationReceived);
    on<SendNotificationRequested>(_onSendSingle);
    on<SendBulkNotificationRequested>(_onSendBulk);
    on<BroadcastNotificationRequested>(_onBroadcast);
    on<BroadcastAdminsRequested>(_onBroadcastAdmins);
    on<NotificationUserSearchChanged>(_onUserSearch);
    on<ClearNotificationStatus>(_onClear);
    // Feed
    on<FetchNotificationsRequested>(_onFetch);
    on<RefreshNotificationsRequested>(_onRefresh);
    on<LoadMoreNotificationsRequested>(_onLoadMore);
    on<FilterNotificationsChanged>(_onFilterChanged);
    on<ClearNotificationFilters>(_onClearFilters);
  }

  final SendNotification sendNotification;
  final SendBulkNotification sendBulkNotification;
  final BroadcastNotification broadcastNotification;
  final BroadcastAdminsNotification broadcastAdminsNotification;
  final NotificationsRepository repository;
  final GetUsers getUsers;
  final GetAllNotifications getAllNotifications;

  static const int _feedLimit = 20;

  StreamSubscription<AdminNotificationEventEntity>? _socketSub;

  void _onConnect(
    ConnectAdminSocket event,
    Emitter<NotificationsState> emit,
  ) {
    repository.connectAdminSocket();

    _socketSub?.cancel();
    _socketSub = repository.adminNotificationStream.listen((notification) {
      if (!isClosed) add(AdminNotificationReceived(notification));
    });

    emit(state.copyWith(socketConnected: true));
  }

  void _onDisconnect(
    DisconnectAdminSocket event,
    Emitter<NotificationsState> emit,
  ) {
    _socketSub?.cancel();
    _socketSub = null;
    repository.disconnectAdminSocket();
    emit(state.copyWith(socketConnected: false));
  }

  void _onAdminNotificationReceived(
    AdminNotificationReceived event,
    Emitter<NotificationsState> emit,
  ) {
    final updated = [event.event, ...state.activityLog].take(50).toList();
    emit(state.copyWith(activityLog: updated, socketConnected: true));
  }

  Future<void> _onSendSingle(
    SendNotificationRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsSendStatus.sending,
      clearError: true,
    ));
    try {
      final result = await sendNotification(
        NotificationRequestEntity(
          userId: event.userId,
          title: event.title,
          body: event.body,
          type: event.type,
          sendPush: event.sendPush,
          data: event.data,
        ),
      );
      emit(state.copyWith(
        status: NotificationsSendStatus.sent,
        lastResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsSendStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> _onSendBulk(
    SendBulkNotificationRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsSendStatus.sending,
      clearError: true,
    ));
    try {
      final result = await sendBulkNotification(
        NotificationRequestEntity(
          userIds: event.userIds,
          title: event.title,
          body: event.body,
          type: event.type,
          sendPush: event.sendPush,
          data: event.data,
        ),
      );
      emit(state.copyWith(
        status: NotificationsSendStatus.sent,
        lastResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsSendStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> _onBroadcast(
    BroadcastNotificationRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsSendStatus.sending,
      clearError: true,
    ));
    try {
      final result = await broadcastNotification(
        NotificationRequestEntity(
          title: event.title,
          body: event.body,
          type: event.type,
          sendPush: event.sendPush,
          data: event.data,
        ),
      );
      emit(state.copyWith(
        status: NotificationsSendStatus.sent,
        lastResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsSendStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> _onBroadcastAdmins(
    BroadcastAdminsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsSendStatus.sending,
      clearError: true,
    ));
    try {
      final result = await broadcastAdminsNotification(
        NotificationRequestEntity(
          title: event.title,
          body: event.body,
          type: event.type,
          sendPush: event.sendPush,
          data: event.data,
        ),
      );
      emit(state.copyWith(
        status: NotificationsSendStatus.sent,
        lastResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsSendStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> _onUserSearch(
    NotificationUserSearchChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(
      userSearchQuery: query,
      userSearchLoading: query.isNotEmpty,
      userSearchResults: query.isEmpty ? [] : state.userSearchResults,
    ));

    if (query.isEmpty) return;

    try {
      final page = await getUsers(page: 1, limit: 10, search: query);
      emit(state.copyWith(
        userSearchResults: page.users,
        userSearchLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        userSearchResults: [],
        userSearchLoading: false,
      ));
    }
  }

  void _onClear(
    ClearNotificationStatus event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(
      status: NotificationsSendStatus.idle,
      clearError: true,
      clearResult: true,
    ));
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Unauthorized. Please log in again.';
    if (msg.contains('403')) return 'Insufficient permissions for this action.';
    if (msg.contains('404')) return 'User not found.';
    if (msg.contains('400')) return 'Invalid request. Please check your inputs.';
    if (msg.contains('500')) return 'Server error. Please try again later.';
    return msg.replaceFirst('Exception: ', '');
  }

  // ── Global notification feed handlers ──────────────────────────────────────

  Future<void> _onFetch(
    FetchNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      notificationsLoading: true,
      notifications: [],
      notificationsPage: 0,
      notificationsHasReachedMax: false,
      clearNotificationsError: true,
    ));
    await _fetchPage(1, emit, replace: true);
  }

  Future<void> _onRefresh(
    RefreshNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      notificationsLoading: true,
      notifications: [],
      notificationsPage: 0,
      notificationsHasReachedMax: false,
      clearNotificationsError: true,
    ));
    await _fetchPage(1, emit, replace: true);
  }

  Future<void> _onLoadMore(
    LoadMoreNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.notificationsHasReachedMax || state.notificationsLoadingMore) {
      return;
    }
    emit(state.copyWith(notificationsLoadingMore: true));
    await _fetchPage(state.notificationsPage + 1, emit, replace: false);
  }

  Future<void> _onFilterChanged(
    FilterNotificationsChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.filters == state.filters) return;
    emit(state.copyWith(
      filters: event.filters,
      notificationsLoading: true,
      notifications: [],
      notificationsPage: 0,
      notificationsHasReachedMax: false,
      clearNotificationsError: true,
    ));
    await _fetchPage(1, emit, replace: true);
  }

  Future<void> _onClearFilters(
    ClearNotificationFilters event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.filters.isEmpty) return;
    emit(state.copyWith(
      filters: const NotificationFilters(),
      notificationsLoading: true,
      notifications: [],
      notificationsPage: 0,
      notificationsHasReachedMax: false,
      clearNotificationsError: true,
    ));
    await _fetchPage(1, emit, replace: true);
  }

  Future<void> _fetchPage(
    int page,
    Emitter<NotificationsState> emit, {
    required bool replace,
  }) async {
    try {
      final result = await getAllNotifications(
        page: page,
        limit: _feedLimit,
        filters: state.filters.isEmpty ? null : state.filters,
      );
      final newList = replace
          ? result.notifications
          : [...state.notifications, ...result.notifications];
      emit(state.copyWith(
        notifications: newList,
        notificationsPage: result.page,
        notificationsTotal: result.total,
        notificationsHasReachedMax: result.page >= result.lastPage,
        notificationsLoading: false,
        notificationsLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        notificationsLoading: false,
        notificationsLoadingMore: false,
        notificationsError: _friendlyError(e),
      ));
    }
  }

  @override
  Future<void> close() {
    _socketSub?.cancel();
    return super.close();
  }
}
