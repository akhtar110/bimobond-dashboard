part of 'notifications_bloc.dart';

enum NotificationsSendStatus { idle, sending, sent, error }

class NotificationsState {
  const NotificationsState({
    this.status = NotificationsSendStatus.idle,
    this.errorMessage,
    this.lastResult,
    this.socketConnected = false,
    this.activityLog = const [],
    this.userSearchResults = const [],
    this.userSearchLoading = false,
    this.userSearchQuery = '',
    // ── Global notification feed ─────────────────────────
    this.notifications = const [],
    this.notificationsPage = 0,
    this.notificationsTotal = 0,
    this.notificationsLoading = false,
    this.notificationsLoadingMore = false,
    this.notificationsHasReachedMax = false,
    this.notificationsError,
    this.filters = const NotificationFilters(),
  });

  final NotificationsSendStatus status;
  final String? errorMessage;
  final NotificationSendResultEntity? lastResult;
  final bool socketConnected;
  final List<AdminNotificationEventEntity> activityLog;

  // User search (shared between single & bulk selector)
  final List<UserEntity> userSearchResults;
  final bool userSearchLoading;
  final String userSearchQuery;

  // Global notification feed
  final List<NotificationEntity> notifications;
  final int notificationsPage;
  final int notificationsTotal;
  final bool notificationsLoading;
  final bool notificationsLoadingMore;
  final bool notificationsHasReachedMax;
  final String? notificationsError;
  final NotificationFilters filters;

  bool get isSending => status == NotificationsSendStatus.sending;
  bool get hasSent => status == NotificationsSendStatus.sent;
  bool get hasError => status == NotificationsSendStatus.error;

  NotificationsState copyWith({
    NotificationsSendStatus? status,
    String? errorMessage,
    bool clearError = false,
    NotificationSendResultEntity? lastResult,
    bool clearResult = false,
    bool? socketConnected,
    List<AdminNotificationEventEntity>? activityLog,
    List<UserEntity>? userSearchResults,
    bool? userSearchLoading,
    String? userSearchQuery,
    // Feed
    List<NotificationEntity>? notifications,
    int? notificationsPage,
    int? notificationsTotal,
    bool? notificationsLoading,
    bool? notificationsLoadingMore,
    bool? notificationsHasReachedMax,
    String? notificationsError,
    bool clearNotificationsError = false,
    NotificationFilters? filters,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      socketConnected: socketConnected ?? this.socketConnected,
      activityLog: activityLog ?? this.activityLog,
      userSearchResults: userSearchResults ?? this.userSearchResults,
      userSearchLoading: userSearchLoading ?? this.userSearchLoading,
      userSearchQuery: userSearchQuery ?? this.userSearchQuery,
      notifications: notifications ?? this.notifications,
      notificationsPage: notificationsPage ?? this.notificationsPage,
      notificationsTotal: notificationsTotal ?? this.notificationsTotal,
      notificationsLoading:
          notificationsLoading ?? this.notificationsLoading,
      notificationsLoadingMore:
          notificationsLoadingMore ?? this.notificationsLoadingMore,
      notificationsHasReachedMax:
          notificationsHasReachedMax ?? this.notificationsHasReachedMax,
      notificationsError: clearNotificationsError
          ? null
          : (notificationsError ?? this.notificationsError),
      filters: filters ?? this.filters,
    );
  }
}
