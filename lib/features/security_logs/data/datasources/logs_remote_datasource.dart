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
      if (query.userId != null && query.userId!.trim().isNotEmpty) {
        try {
          final response = await _dio.get(
            '/users/admin/${query.userId}/audit-logs',
          );
          final rawData = response.data;
          if (rawData is List) {
            final items = rawData.whereType<Map>().map((e) {
              final map = Map<String, dynamic>.from(e);
              final moderator = map['moderator'] is Map
                  ? Map<String, dynamic>.from(map['moderator'] as Map)
                  : null;
              return LogModel.fromJson({
                'id': map['id'],
                'createdAt': map['createdAt'],
                'category': 'MODERATION',
                'action': map['action'],
                'actorId': map['moderatorId'] ?? moderator?['id'],
                'actorRole': 'MODERATOR',
                'userFullName': moderator?['fullName'],
                'userName': moderator?['username'],
                'userEmail': moderator?['email'],
                'avatarUrl': moderator?['avatarUrl'],
                'targetType': 'USER',
                'targetId': map['targetUserId'],
                'description': map['note'] ?? map['reason'],
                'meta': {
                  if (map['reason'] != null) 'reason': map['reason'],
                  if (map['note'] != null) 'note': map['note'],
                  if (map['oldValue'] != null) 'oldValue': map['oldValue'],
                  if (map['newValue'] != null) 'newValue': map['newValue'],
                },
                'raw': map,
              });
            }).toList(growable: false);

            return LogsResponseModel(
              data: items,
              meta: PaginationMeta(
                total: items.length,
                page: query.page,
                limit: query.limit,
                totalPages: 1,
              ),
            );
          } else if (rawData is Map<String, dynamic>) {
            return LogsResponseModel.fromJson(rawData);
          }
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) {
            // Continue to fallback endpoint if not 404 or on error
          }
        }
      }

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
