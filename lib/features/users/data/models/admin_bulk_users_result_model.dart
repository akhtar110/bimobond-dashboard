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

    return AdminBulkUsersResultModel(
      action: action,
      successCount: _readInt(json['successCount']) ?? 0,
      failedCount: _readInt(json['failedCount']) ?? 0,
      notFoundCount: _readInt(json['notFoundCount']) ?? 0,
      userIds: _readStringList(json['userIds']),
      notFoundIds: _readStringList(json['notFoundIds']),
      reason: json['reason']?.toString(),
      until: json['until'] is String && (json['until'] as String).isNotEmpty
          ? DateTime.tryParse(json['until'] as String)
          : null,
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
