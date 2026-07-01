import '../entities/admin_notification_event_entity.dart';
import '../entities/notification_filters.dart';
import '../entities/notification_request_entity.dart';
import '../entities/notification_send_result_entity.dart';
import '../entities/scheduled_notification_entity.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationsRepository {
  Future<NotificationSendResultEntity> sendToUser(
    NotificationRequestEntity request,
  );

  Future<NotificationSendResultEntity> sendBulk(
    NotificationRequestEntity request,
  );

  Future<NotificationSendResultEntity> broadcast(
    NotificationRequestEntity request,
  );

  Future<NotificationSendResultEntity> broadcastAdmins(
    NotificationRequestEntity request,
  );

  Stream<AdminNotificationEventEntity> get adminNotificationStream;

  void connectAdminSocket();
  void disconnectAdminSocket();
  bool get isSocketConnected;

  Future<NotificationFeedResponse> getAllNotifications({
    int page = 1,
    int limit = 20,
    NotificationFilters? filters,
  });

  Future<ScheduledNotificationEntity> scheduleNotification({
    required NotificationRequestEntity request,
    required ScheduledNotificationTarget target,
  });
}
