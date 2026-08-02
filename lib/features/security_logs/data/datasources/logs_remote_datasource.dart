import 'package:dio/dio.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/log_entity.dart';
import '../models/log_models.dart';

abstract class LogsRemoteDataSource {
  Future<PaginatedResult<LogEntity>> getLogs(LogsQuery query);
}

class LogsRemoteDataSourceImpl implements LogsRemoteDataSource {
  LogsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<LogEntity>> getLogs(LogsQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user-history/admin/logs',
        queryParameters: query.toQueryParameters(),
      );
      return LogsResponseModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw Exception(_dioMessage(e));
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['msg'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return e.message ?? e.toString();
  }
}
