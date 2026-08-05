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
    try {
      final endpoint = (query.deviceId != null && query.deviceId!.trim().isNotEmpty)
          ? '/users/admin/$userId/devices/${query.deviceId!.trim()}/history'
          : '/user-history/admin/users/$userId';
      final response = await _dio.get(
        endpoint,
        queryParameters: query.toQueryParameters(),
      );
      final data = _asMap(response.data);
      return UserHistoryResponseModel.fromJson(data).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 &&
          (query.deviceId == null || query.deviceId!.trim().isEmpty)) {
        final response = await _dio.get(
          '/activity/admin/users/$userId/timeline',
          queryParameters: query.toQueryParameters(),
        );
        final data = _asMap(response.data);
        return UserHistoryResponseModel.fromJson(data).toEntity();
      }
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid user history API response');
  }
}
