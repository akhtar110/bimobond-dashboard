import '../../domain/entities/admin_bulk_user_action.dart';
import '../../domain/entities/admin_bulk_users_result_entity.dart';

class AdminBulkUsersResultModel extends AdminBulkUsersResultEntity {
  const AdminBulkUsersResultModel({
    required super.action,
    required super.successCount,
    required super.failedCount,
    required super.notFoundCount,
    required super.userIds,
    required super.notFoundIds,
    super.reason,
    super.until,
    super.roles,
    super.failed,
  });

  factory AdminBulkUsersResultModel.fromJson(
    Map<String, dynamic> json,
    AdminBulkUserAction fallbackAction,
  ) {
    final actionRaw = json['action']?.toString();
    final action = AdminBulkUserAction.values.firstWhere(
      (value) => value.apiValue == actionRaw,
      orElse: () => fallbackAction,
    );

    final failedRaw = json['failed'];
    final failed = <AdminBulkUserFailureEntity>[];
    if (failedRaw is List) {
      for (final item in failedRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final userId = map['userId']?.toString() ?? '';
        final message = map['message']?.toString() ?? '';
        if (userId.isEmpty && message.isEmpty) continue;
        failed.add(
          AdminBulkUserFailureEntity(
            userId: userId.isEmpty ? 'unknown' : userId,
            message: message.isEmpty ? 'Failed' : message,
          ),
        );
      }
    }

    return AdminBulkUsersResultModel(
      action: action,
      successCount: _readInt(json['successCount']) ?? 0,
      failedCount: _readInt(json['failedCount']) ?? failed.length,
      notFoundCount: _readInt(json['notFoundCount']) ?? 0,
      userIds: _readStringList(json['userIds']),
      notFoundIds: _readStringList(json['notFoundIds']),
      reason: json['reason']?.toString(),
      until: json['until'] is String && (json['until'] as String).isNotEmpty
          ? DateTime.tryParse(json['until'] as String)
          : null,
      roles: _readStringList(json['roles']),
      failed: failed,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
