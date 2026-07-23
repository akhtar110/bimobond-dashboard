class BulkGiftActionResult {
  const BulkGiftActionResult({
    required this.action,
    required this.successCount,
    required this.notFoundCount,
    required this.giftIds,
    required this.notFoundIds,
    this.deactivatedCount = 0,
    this.deactivatedIds = const [],
    this.errorMessage,
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> giftIds;
  final List<String> notFoundIds;
  final int deactivatedCount;
  final List<String> deactivatedIds;
  final String? errorMessage;

  bool get isFullSuccess =>
      errorMessage == null && notFoundCount == 0 && notFoundIds.isEmpty;

  /// Hard-deleted gift ids (DELETE action only).
  List<String> get removedGiftIds =>
      action == 'DELETE' ? giftIds : const [];

  /// Ids that succeeded for activate/deactivate, or deleted for DELETE.
  List<String> get succeededGiftIds {
    if (action == 'DELETE') return giftIds;
    return giftIds;
  }

  /// Legacy alias used by bloc updates.
  List<String> get failedGiftIds => notFoundIds;
}
