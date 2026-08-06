import 'package:dio/dio.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/log_entity.dart';
import '../models/log_models.dart';

abstract class UserViolationsRemoteDataSource {
  Future<PaginatedResult<LogEntity>> getUserViolations({
    required String userId,
    int page = 1,
    int limit = 15,
  });
}

class UserViolationsRemoteDataSourceImpl implements UserViolationsRemoteDataSource {
  UserViolationsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<LogEntity>> getUserViolations({
    required String userId,
    int page = 1,
    int limit = 15,
  }) async {
    try {
      // Primary Endpoint: GET /user-reports/admin/users/:userId/violations
      final response = await _dio.get(
        '/user-reports/admin/users/$userId/violations',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return LogsResponseModel.fromJson(data);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          // Secondary Endpoint: GET /users/admin/:userId/violations
          final response = await _dio.get(
            '/users/admin/$userId/violations',
            queryParameters: {
              'page': page,
              'limit': limit,
            },
          );
          final data = response.data;
          if (data is Map<String, dynamic>) {
            return LogsResponseModel.fromJson(data);
          }
        } on DioException catch (_) {
          try {
            // Fallback to Category Filter: /user-history/admin/logs?userId=X&category=MODERATION
            final response = await _dio.get<Map<String, dynamic>>(
              '/user-history/admin/logs',
              queryParameters: {
                'userId': userId,
                'category': 'MODERATION',
                'page': page,
                'limit': limit,
              },
            );
            return LogsResponseModel.fromJson(response.data ?? const {});
          } on DioException catch (_) {
            return LogsResponseModel(
              data: const [],
              meta: PaginationMeta(total: 0, page: page, limit: limit, totalPages: 1),
            );
          }
        }
      }
      return LogsResponseModel(
        data: const [],
        meta: PaginationMeta(total: 0, page: page, limit: limit, totalPages: 1),
      );
    }

    // Default fallback
    return LogsResponseModel(
      data: const [],
      meta: PaginationMeta(total: 0, page: page, limit: limit, totalPages: 1),
    );
  }
}
