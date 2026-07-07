import 'notification_type.dart';

enum ScheduledNotificationTarget {
  single,
  bulk,
  broadcastAll,
  broadcastAdmins,
}

enum ScheduledNotificationStatus {
  pending,
  sent,
  cancelled,
  failed,
}

/// Optional recurring rule placeholder for future backend support.
class RecurringScheduleRule {
  const RecurringScheduleRule({
    required this.frequency,
    this.interval = 1,
    this.endDate,
  });

  final String frequency;
  final int interval;
  final DateTime? endDate;
}

class ScheduledNotificationEntity {
  const ScheduledNotificationEntity({
    required this.id,
    required this.scheduledAt,
    required this.timezoneName,
    required this.title,
    required this.body,
    required this.type,
    required this.sendPush,
    required this.target,
    this.userId,
    this.userIds,
    this.data,
    this.recurringRule,
    this.status = ScheduledNotificationStatus.pending,
    required this.createdAt,
  });

  final String id;
  final DateTime scheduledAt;
  final String timezoneName;
  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;
  final ScheduledNotificationTarget target;
  final String? userId;
  final List<String>? userIds;
  final Map<String, dynamic>? data;
  final RecurringScheduleRule? recurringRule;
  final ScheduledNotificationStatus status;
  final DateTime createdAt;

  ScheduledNotificationEntity copyWith({
    ScheduledNotificationStatus? status,
  }) {
    return ScheduledNotificationEntity(
      id: id,
      scheduledAt: scheduledAt,
      timezoneName: timezoneName,
      title: title,
      body: body,
      type: type,
      sendPush: sendPush,
      target: target,
      userId: userId,
      userIds: userIds,
      data: data,
      recurringRule: recurringRule,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
