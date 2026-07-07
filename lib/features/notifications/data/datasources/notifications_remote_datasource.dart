import 'package:dio/dio.dart';

import '../../domain/entities/notification_filters.dart';
import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_send_result_entity.dart';
import '../../domain/entities/scheduled_notification_entity.dart';
import '../models/notification_model.dart';
import '../models/notification_request_model.dart';
import '../models/notification_send_result_model.dart';

abstract class NotificationsRemoteDataSource {
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

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<NotificationSendResultEntity> sendToUser(
    NotificationRequestEntity request,
  ) async {
    final body = NotificationRequestModel(request).toJsonSingle();
    final response = await _dio.post(
      '/notifications/admin/send',
      data: body,
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return NotificationSendResultModel.fromJson(data);
  }

  @override
  Future<NotificationSendResultEntity> sendBulk(
    NotificationRequestEntity request,
  ) async {
    final body = NotificationRequestModel(request).toJsonBulk();
    final response = await _dio.post(
      '/notifications/admin/send-bulk',
      data: body,
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return NotificationSendResultModel.fromJson({
      'sentCount': (data['sentCount'] as num?)?.toInt() ?? 0,
      ...data,
    });
  }

  @override
  Future<NotificationSendResultEntity> broadcast(
    NotificationRequestEntity request,
  ) async {
    final body = NotificationRequestModel(request).toJsonBroadcast();
    final response = await _dio.post(
      '/notifications/admin/broadcast',
      data: body,
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return NotificationSendResultModel.fromJson(data);
  }

  @override
  Future<NotificationSendResultEntity> broadcastAdmins(
    NotificationRequestEntity request,
  ) async {
    final body = NotificationRequestModel(request).toJsonBroadcast();
    final response = await _dio.post(
      '/notifications/admin/broadcast-admins',
      data: body,
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return NotificationSendResultModel.fromJson(data);
  }

  @override
  Future<NotificationFeedResponse> getAllNotifications({
    int page = 1,
    int limit = 20,
    NotificationFilters? filters,
  }) async {
    final response = await _dio.get(
      '/notifications/admin/all',
      queryParameters: {
        'page': page,
        'limit': limit,
        ...?filters?.toQueryParams(),
      },
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return NotificationFeedResponse.fromJson(data);
  }

  @override
  Future<ScheduledNotificationEntity> scheduleNotification({
    required NotificationRequestEntity request,
    required ScheduledNotificationTarget target,
  }) async {
    final model = NotificationRequestModel(request);
    final targetValue = switch (target) {
      ScheduledNotificationTarget.single => 'single',
      ScheduledNotificationTarget.bulk => 'bulk',
      ScheduledNotificationTarget.broadcastAll => 'broadcast',
      ScheduledNotificationTarget.broadcastAdmins => 'broadcast_admins',
    };

    final body = model.toJsonSchedule(
      target: targetValue,
      userId: request.userId,
      userIds: request.userIds,
    );

    final response = await _dio.post(
      '/notifications/admin/schedule',
      data: body,
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final nested = data['data'];
    final json = nested is Map<String, dynamic> ? nested : data;

    return ScheduledNotificationEntity(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          request.scheduledAt ??
          DateTime.now(),
      timezoneName:
          json['timezone']?.toString() ?? request.timezoneName ?? 'UTC',
      title: request.title,
      body: request.body,
      type: request.type,
      sendPush: request.sendPush,
      target: target,
      userId: request.userId,
      userIds: request.userIds,
      data: request.data,
      createdAt: DateTime.now(),
    );
  }
}
