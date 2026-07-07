import '../../../../features/post_management/domain/entities/managed_post_entity.dart';

class BulkPostActionResult {
  const BulkPostActionResult({
    required this.updatedPosts,
    required this.removedPostIds,
    required this.failedPostIds,
    this.succeededPostIds = const [],
    this.errorMessage,
  });

  final List<ManagedPostEntity> updatedPosts;
  final List<String> removedPostIds;
  final List<String> failedPostIds;

  /// Post IDs that succeeded when the bulk API returns no post bodies.
  final List<String> succeededPostIds;
  final String? errorMessage;

  bool get hasFailures => failedPostIds.isNotEmpty;
  bool get isFullSuccess => failedPostIds.isEmpty;

  int get successCount {
    if (updatedPosts.isNotEmpty || removedPostIds.isNotEmpty) {
      return updatedPosts.length + removedPostIds.length;
    }
    return succeededPostIds.length;
  }
}
