class BulkGiftActionResult {
  const BulkGiftActionResult({
    required this.removedGiftIds,
    required this.failedGiftIds,
    this.succeededGiftIds = const [],
    this.errorMessage,
  });

  final List<String> removedGiftIds;
  final List<String> failedGiftIds;
  final List<String> succeededGiftIds;
  final String? errorMessage;

  bool get isFullSuccess => failedGiftIds.isEmpty;

  int get successCount {
    if (removedGiftIds.isNotEmpty) {
      return removedGiftIds.length;
    }
    return succeededGiftIds.length;
  }
}
