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
}
