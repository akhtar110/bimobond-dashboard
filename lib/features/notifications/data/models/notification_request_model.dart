import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_type.dart';

class NotificationRequestModel {
  const NotificationRequestModel(this.entity);
  final NotificationRequestEntity entity;

  Map<String, dynamic> _scheduleFields() => {
        if (entity.scheduledAt != null)
          'scheduledAt': entity.scheduledAt!.toUtc().toIso8601String(),
        if (entity.timezoneName != null) 'timezone': entity.timezoneName,
      };

  Map<String, dynamic> toJsonSingle() => {
        'userId': entity.userId,
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
        ..._scheduleFields(),
      };

  Map<String, dynamic> toJsonBulk() => {
        'userIds': entity.userIds ?? [],
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
        ..._scheduleFields(),
      };

  Map<String, dynamic> toJsonBroadcast() => {
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
        ..._scheduleFields(),
      };

  Map<String, dynamic> toJsonSchedule({
    required String target,
    String? userId,
    List<String>? userIds,
  }) =>
      {
        'target': target,
        if (userId != null) 'userId': userId,
        if (userIds != null) 'userIds': userIds,
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
        ..._scheduleFields(),
      };
}
