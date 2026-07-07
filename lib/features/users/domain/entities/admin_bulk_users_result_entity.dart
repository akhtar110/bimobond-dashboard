import 'admin_bulk_user_action.dart';

class AdminBulkUsersResultEntity {
  const AdminBulkUsersResultEntity({
    required this.action,
    required this.successCount,
    required this.failedCount,
    required this.notFoundCount,
    required this.userIds,
    required this.notFoundIds,
    this.reason,
    this.until,
  });

  final AdminBulkUserAction action;
  final int successCount;
  final int failedCount;
  final int notFoundCount;
  final List<String> userIds;
  final List<String> notFoundIds;
  final String? reason;
  final DateTime? until;

  bool get isFullSuccess => failedCount == 0 && notFoundCount == 0;
  bool get isPartialSuccess => successCount > 0 && !isFullSuccess;
  bool get isTotalFailure => successCount == 0;

  String messageFor(String actionLabel) {
    final buffer = StringBuffer('$actionLabel: $successCount succeeded');
    if (failedCount > 0) {
      buffer.write(', $failedCount failed');
    }
    if (notFoundCount > 0) {
      buffer.write(', $notFoundCount not found');
    }
    return buffer.toString();
  }
}
