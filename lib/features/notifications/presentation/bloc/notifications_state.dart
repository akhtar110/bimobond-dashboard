part of 'notifications_bloc.dart';

enum NotificationsSendStatus { idle, sending, sent, scheduled, error }

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
    this.notificationsLastPage = 1,
    this.notificationsLoading = false,
    this.notificationsLoadingMore = false,
    this.notificationsHasReachedMax = false,
    this.notificationsError,
    this.filters = const NotificationFilters(),
    // ── Scheduling ───────────────────────────────────────
    this.isScheduled = false,
    this.scheduledDateTime,
    this.scheduledNotifications = const [],
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
  final int notificationsLastPage;
  final bool notificationsLoading;
  final bool notificationsLoadingMore;
  final bool notificationsHasReachedMax;
  final String? notificationsError;
  final NotificationFilters filters;

  // Scheduling
  final bool isScheduled;
  final DateTime? scheduledDateTime;
  final List<ScheduledNotificationEntity> scheduledNotifications;

  bool get isSending => status == NotificationsSendStatus.sending;
  bool get hasSent => status == NotificationsSendStatus.sent;
  bool get hasScheduled => status == NotificationsSendStatus.scheduled;
  bool get hasError => status == NotificationsSendStatus.error;

  List<ScheduledNotificationEntity> get pendingScheduledNotifications =>
      scheduledNotifications
          .where((item) => item.status == ScheduledNotificationStatus.pending)
          .toList(growable: false);

  int get pendingScheduledCount => pendingScheduledNotifications.length;

  DateTime? get nextScheduledAt {
    final pending = pendingScheduledNotifications;
    if (pending.isEmpty) return null;
    final sorted = [...pending]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return sorted.first.scheduledAt;
  }

  bool get isScheduleValid {
    if (!isScheduled) return true;
    final scheduledAt = scheduledDateTime;
    if (scheduledAt == null) return false;
    return scheduledAt.isAfter(DateTime.now());
  }

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
    int? notificationsLastPage,
    bool? notificationsLoading,
    bool? notificationsLoadingMore,
    bool? notificationsHasReachedMax,
    String? notificationsError,
    bool clearNotificationsError = false,
    NotificationFilters? filters,
    // Scheduling
    bool? isScheduled,
    DateTime? scheduledDateTime,
    bool clearScheduledDateTime = false,
    List<ScheduledNotificationEntity>? scheduledNotifications,
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
      notificationsLastPage:
          notificationsLastPage ?? this.notificationsLastPage,
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
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledDateTime: clearScheduledDateTime
          ? null
          : (scheduledDateTime ?? this.scheduledDateTime),
      scheduledNotifications:
          scheduledNotifications ?? this.scheduledNotifications,
    );
  }
}
