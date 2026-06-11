import '../../../../features/post_management/domain/entities/managed_post_entity.dart';

sealed class BulkSinglePostResult {}

class BulkSinglePostUpdated extends BulkSinglePostResult {
  BulkSinglePostUpdated(this.post);
  final ManagedPostEntity post;
}

class BulkSinglePostRemoved extends BulkSinglePostResult {
  BulkSinglePostRemoved(this.postId);
  final String postId;
}
