class BulkAdminGiftActionResult {
  const BulkAdminGiftActionResult({
    required this.action,
    this.successCount = 0,
    this.notFoundCount = 0,
    this.giftIds = const [],
    this.notFoundIds = const [],
    this.deactivatedCount = 0,
    this.deactivatedIds = const [],
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> giftIds;
  final List<String> notFoundIds;
  final int deactivatedCount;
  final List<String> deactivatedIds;

  bool get isFullSuccess => notFoundCount == 0 && notFoundIds.isEmpty;
}
