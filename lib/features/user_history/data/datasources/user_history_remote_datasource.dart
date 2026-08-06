import 'package:dio/dio.dart';

import '../../domain/entities/user_history_entity.dart';
import '../models/user_history_models.dart';

abstract class UserHistoryRemoteDataSource {
  Future<UserHistoryPageEntity> getUserHistory({
    required String userId,
    required UserHistoryQuery query,
  });
}

class UserHistoryRemoteDataSourceImpl implements UserHistoryRemoteDataSource {
  UserHistoryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserHistoryPageEntity> getUserHistory({
    required String userId,
    required UserHistoryQuery query,
  }) async {
    if (query.deviceId != null && query.deviceId!.trim().isNotEmpty) {
      return _getDeviceHistory(userId, query);
    }

    if (query.prefersTimelineEndpoint) {
      return _getTimeline(userId, query);
    }

    try {
      return await _getAuditLogs(userId, query);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _getTimeline(userId, query);
      }
      throw Exception(_dioMessage(e));
    }
  }

  Future<UserHistoryPageEntity> _getDeviceHistory(
    String userId,
    UserHistoryQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/users/admin/$userId/devices/${query.deviceId!.trim()}/history',
        queryParameters: query.toQueryParameters(),
      );
      return UserHistoryResponseModel.fromJson(_asMap(response.data)).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const UserHistoryPageEntity(
          items: [],
          meta: UserHistoryMetaEntity(
            total: 0,
            page: 1,
            limit: 15,
            totalPages: 1,
          ),
        );
      }
      throw Exception(_dioMessage(e));
    }
  }

  Future<UserHistoryPageEntity> _getAuditLogs(
    String userId,
    UserHistoryQuery query,
  ) async {
    final response = await _dio.get(
      '/user-history/admin/users/$userId',
      queryParameters: query.toQueryParameters(),
    );
    return UserHistoryResponseModel.fromJson(_asMap(response.data)).toEntity();
  }

  Future<UserHistoryPageEntity> _getTimeline(
    String userId,
    UserHistoryQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/activity/admin/users/$userId/timeline',
        queryParameters: query.toQueryParameters(forTimeline: true),
      );
      return UserHistoryResponseModel.fromJson(_asMap(response.data)).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const UserHistoryPageEntity(
          items: [],
          meta: UserHistoryMetaEntity(
            total: 0,
            page: 1,
            limit: 15,
            totalPages: 1,
          ),
        );
      }
      throw Exception(_dioMessage(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) {
      return <String, dynamic>{
        'data': data,
        'meta': <String, dynamic>{
          'total': data.length,
          'page': 1,
          'limit': data.isNotEmpty ? data.length : 30,
          'totalPages': 1,
        },
      };
    }
    return <String, dynamic>{'data': const []};
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['msg'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (e.response?.statusCode == 404) {
      return 'User history resource not found (404)';
    }
    return e.message ?? e.toString();
  }
}
