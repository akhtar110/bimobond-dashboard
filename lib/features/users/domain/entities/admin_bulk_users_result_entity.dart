import 'admin_bulk_user_action.dart';

class AdminBulkUserFailureEntity {
  const AdminBulkUserFailureEntity({
    required this.userId,
    required this.message,
  });

  final String userId;
  final String message;
}

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
    this.roles = const [],
    this.failed = const [],
  });

  final AdminBulkUserAction action;
  final int successCount;
  final int failedCount;
  final int notFoundCount;
  final List<String> userIds;
  final List<String> notFoundIds;
  final String? reason;
  final DateTime? until;
  final List<String> roles;
  final List<AdminBulkUserFailureEntity> failed;

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
    if (failed.isNotEmpty) {
      final details = failed
          .take(3)
          .map((f) => '${f.userId}: ${f.message}')
          .join('; ');
      buffer.write('. $details');
      if (failed.length > 3) {
        buffer.write(' (+${failed.length - 3} more)');
      }
    }
    return buffer.toString();
  }
}
