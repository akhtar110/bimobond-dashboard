/// Result of a single call to `POST /posts/admin/bulk`.
class BulkAdminActionResult {
  const BulkAdminActionResult({
    required this.affectedPostIds,
    required this.isDelete,
    this.failedPostIds = const [],
  });

  final List<String> affectedPostIds;
  final List<String> failedPostIds;
  final bool isDelete;

  bool get isFullSuccess => failedPostIds.isEmpty;
}
