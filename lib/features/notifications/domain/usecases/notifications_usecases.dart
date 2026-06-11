import '../entities/notification_filters.dart';
import '../entities/notification_request_entity.dart';
import '../entities/notification_send_result_entity.dart';
import '../repositories/notifications_repository.dart';
import '../../data/models/notification_model.dart';

class SendNotification {
  const SendNotification(this._repo);
  final NotificationsRepository _repo;

  Future<NotificationSendResultEntity> call(
    NotificationRequestEntity request,
  ) =>
      _repo.sendToUser(request);
}

class SendBulkNotification {
  const SendBulkNotification(this._repo);
  final NotificationsRepository _repo;

  Future<NotificationSendResultEntity> call(
    NotificationRequestEntity request,
  ) =>
      _repo.sendBulk(request);
}

class BroadcastNotification {
  const BroadcastNotification(this._repo);
  final NotificationsRepository _repo;

  Future<NotificationSendResultEntity> call(
    NotificationRequestEntity request,
  ) =>
      _repo.broadcast(request);
}

class BroadcastAdminsNotification {
  const BroadcastAdminsNotification(this._repo);
  final NotificationsRepository _repo;

  Future<NotificationSendResultEntity> call(
    NotificationRequestEntity request,
  ) =>
      _repo.broadcastAdmins(request);
}

class GetAllNotifications {
  const GetAllNotifications(this._repo);
  final NotificationsRepository _repo;

  Future<NotificationFeedResponse> call({
    int page = 1,
    int limit = 20,
    NotificationFilters? filters,
  }) =>
      _repo.getAllNotifications(page: page, limit: limit, filters: filters);
}
