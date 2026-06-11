import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_type.dart';

class NotificationRequestModel {
  const NotificationRequestModel(this.entity);
  final NotificationRequestEntity entity;

  Map<String, dynamic> toJsonSingle() => {
        'userId': entity.userId,
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
      };

  Map<String, dynamic> toJsonBulk() => {
        'userIds': entity.userIds ?? [],
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
      };

  Map<String, dynamic> toJsonBroadcast() => {
        'title': entity.title,
        'body': entity.body,
        'type': entity.type.value,
        'sendPush': entity.sendPush,
        if (entity.data != null) 'data': entity.data,
      };
}
