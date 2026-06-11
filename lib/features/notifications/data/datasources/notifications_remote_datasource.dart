import 'package:dio/dio.dart';

import '../../domain/entities/notification_filters.dart';
import '../../domain/entities/notification_request_entity.dart';
import '../../domain/entities/notification_send_result_entity.dart';
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
    print("Notifications data >>>>>$data");
    return NotificationFeedResponse.fromJson(data);
  }
}
