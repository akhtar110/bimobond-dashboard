import '../../domain/entities/admin_notification_event_entity.dart';
import '../../domain/entities/notification_filters.dart';
import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_send_result_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../datasources/notifications_socket_service.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.socketService,
  });

  final NotificationsRemoteDataSource remoteDataSource;
  final NotificationsSocketService socketService;

  @override
  Future<NotificationSendResultEntity> sendToUser(
    NotificationRequestEntity request,
  ) =>
      remoteDataSource.sendToUser(request);

  @override
  Future<NotificationSendResultEntity> sendBulk(
    NotificationRequestEntity request,
  ) =>
      remoteDataSource.sendBulk(request);

  @override
  Future<NotificationSendResultEntity> broadcast(
    NotificationRequestEntity request,
  ) =>
      remoteDataSource.broadcast(request);

  @override
  Future<NotificationSendResultEntity> broadcastAdmins(
    NotificationRequestEntity request,
  ) =>
      remoteDataSource.broadcastAdmins(request);

  @override
  Stream<AdminNotificationEventEntity> get adminNotificationStream =>
      socketService.adminNotifications;

  @override
  void connectAdminSocket() => socketService.connect();

  @override
  void disconnectAdminSocket() => socketService.disconnect();

  @override
  bool get isSocketConnected => socketService.isConnected;

  @override
  Future<NotificationFeedResponse> getAllNotifications({
    int page = 1,
    int limit = 20,
    NotificationFilters? filters,
  }) =>
      remoteDataSource.getAllNotifications(
        page: page,
        limit: limit,
        filters: filters,
      );
}
