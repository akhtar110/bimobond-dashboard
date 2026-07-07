import '../../domain/entities/admin_notification_event_entity.dart';

class AdminNotificationEventModel extends AdminNotificationEventEntity {
  const AdminNotificationEventModel({
    super.scope,
    required super.sentCount,
    super.title,
    super.body,
    required super.receivedAt,
  });

  factory AdminNotificationEventModel.fromSocketData(
    dynamic data,
  ) {
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    return AdminNotificationEventModel(
      scope: map['scope'] as String?,
      sentCount: (map['sentCount'] as num?)?.toInt() ?? 0,
      title: map['title'] as String?,
      body: map['body'] as String?,
      receivedAt: DateTime.now(),
    );
  }
}
