class BulkAdminGiftActionResult {
  const BulkAdminGiftActionResult({
    required this.affectedGiftIds,
    this.failedGiftIds = const [],
    this.isDelete = false,
  });

  final List<String> affectedGiftIds;
  final List<String> failedGiftIds;
  final bool isDelete;

  bool get isFullSuccess => failedGiftIds.isEmpty;
}
