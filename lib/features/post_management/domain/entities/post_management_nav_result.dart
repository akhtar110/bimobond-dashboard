import 'managed_post_entity.dart';

/// Explicit navigation result from [PostManagementDetailScreen].
/// Avoids treating route [arguments] or incidental [ManagedPostEntity] values
/// as a list patch when the admin only viewed the post.
class PostManagementNavResult {
  const PostManagementNavResult._({this.post, this.deleted = false});

  const PostManagementNavResult.updated(ManagedPostEntity post)
      : this._(post: post);

  const PostManagementNavResult.deleted() : this._(deleted: true);

  final ManagedPostEntity? post;
  final bool deleted;
}
