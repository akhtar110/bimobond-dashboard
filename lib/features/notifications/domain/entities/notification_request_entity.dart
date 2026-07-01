import 'notification_type.dart';

class NotificationRequestEntity {
  const NotificationRequestEntity({
    this.userId,
    this.userIds,
    required this.title,
    required this.body,
    this.type = NotificationType.adminMessage,
    this.sendPush = true,
    this.data,
    this.scheduledAt,
    this.timezoneName,
  });

  /// Single recipient (used with send endpoint).
  final String? userId;

  /// Multiple recipients (used with send-bulk endpoint).
  final List<String>? userIds;

  final String title;
  final String body;
  final NotificationType type;
  final bool sendPush;

  /// Optional JSON data for deep linking.
  final Map<String, dynamic>? data;

  /// When set, the notification should be delivered later (API-ready).
  final DateTime? scheduledAt;

  /// IANA or local timezone label for scheduled delivery.
  final String? timezoneName;
}
