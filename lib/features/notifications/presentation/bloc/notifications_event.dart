part of 'notifications_bloc.dart';

abstract class NotificationsEvent {
  const NotificationsEvent();
}

class ConnectAdminSocket extends NotificationsEvent {
  const ConnectAdminSocket();
}

class DisconnectAdminSocket extends NotificationsEvent {
  const DisconnectAdminSocket();
}

/// Fired by the socket stream when a new admin broadcast arrives.
class AdminNotificationReceived extends NotificationsEvent {
  const AdminNotificationReceived(this.event);
  final AdminNotificationEventEntity event;
}

class SendNotificationRequested extends NotificationsEvent {
  const SendNotificationRequested({
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    this.data,
  });

  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final Map<String, dynamic>? data;
}

class SendBulkNotificationRequested extends NotificationsEvent {
  const SendBulkNotificationRequested({
    required this.userIds,
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    this.data,
  });

  final List<String> userIds;
  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final Map<String, dynamic>? data;
}

class BroadcastNotificationRequested extends NotificationsEvent {
  const BroadcastNotificationRequested({
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    this.data,
  });

  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final Map<String, dynamic>? data;
}

class BroadcastAdminsRequested extends NotificationsEvent {
  const BroadcastAdminsRequested({
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    this.data,
  });

  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final Map<String, dynamic>? data;
}

class NotificationUserSearchChanged extends NotificationsEvent {
  const NotificationUserSearchChanged(this.query);
  final String query;
}

class ClearNotificationStatus extends NotificationsEvent {
  const ClearNotificationStatus();
}

// ── Global notification feed events ─────────────────────────────────────────

class FetchNotificationsRequested extends NotificationsEvent {
  const FetchNotificationsRequested();
}

class RefreshNotificationsRequested extends NotificationsEvent {
  const RefreshNotificationsRequested();
}

class LoadMoreNotificationsRequested extends NotificationsEvent {
  const LoadMoreNotificationsRequested();
}

class ChangeNotificationsPageRequested extends NotificationsEvent {
  const ChangeNotificationsPageRequested(this.page);

  final int page;
}

class FilterNotificationsChanged extends NotificationsEvent {
  const FilterNotificationsChanged(this.filters);
  final NotificationFilters filters;
}

class ClearNotificationFilters extends NotificationsEvent {
  const ClearNotificationFilters();
}

// ── Scheduling events ───────────────────────────────────────────────────────

class NotificationScheduleModeChanged extends NotificationsEvent {
  const NotificationScheduleModeChanged(this.isScheduled);
  final bool isScheduled;
}

class NotificationScheduleUpdated extends NotificationsEvent {
  const NotificationScheduleUpdated(this.scheduledDateTime);
  final DateTime? scheduledDateTime;
}

class ScheduleNotificationRequested extends NotificationsEvent {
  const ScheduleNotificationRequested({
    required this.target,
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    this.userId,
    this.userIds,
    this.data,
    this.recurringRule,
  });

  final ScheduledNotificationTarget target;
  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final String? userId;
  final List<String>? userIds;
  final Map<String, dynamic>? data;
  final RecurringScheduleRule? recurringRule;
}

class CancelScheduledNotification extends NotificationsEvent {
  const CancelScheduledNotification(this.id);
  final String id;
}
