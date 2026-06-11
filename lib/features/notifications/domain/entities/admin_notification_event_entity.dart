/// Real-time admin notification event received via Socket.IO
/// (`adminNotification` event from the `admins` room).
class AdminNotificationEventEntity {
  const AdminNotificationEventEntity({
    this.scope,
    required this.sentCount,
    this.title,
    this.body,
    required this.receivedAt,
  });

  /// e.g. 'broadcast' or 'broadcast-admins'
  final String? scope;
  final int sentCount;
  final String? title;
  final String? body;
  final DateTime receivedAt;
}
