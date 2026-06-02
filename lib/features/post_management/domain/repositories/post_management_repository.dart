import '../entities/comment_entity.dart';
import '../entities/managed_post_entity.dart';

abstract class PostManagementRepository {
  Future<ManagedPostEntity> getManagedPostById(String postId);
  Future<ManagedPostEntity> updateManagedPost(
    String postId,
    ManagedPostUpdateData data,
  );
  Future<void> deleteManagedPost(String postId);

  // ── NEW admin actions ──────────────────────────────────────
  Future<ManagedPostEntity> updatePostDetails(
    String postId, {
    String? description,
    String? category,
  });
  Future<ManagedPostEntity> hidePost(String postId);
  Future<ManagedPostEntity> banPost(String postId);
  Future<ManagedPostEntity> updatePostStatus(String postId, String status);

  Future<PostCommentsPageEntity> getPostComments(
    String postId, {
    required int page,
    required int limit,
  });

  Future<void> deleteCommentAsAdmin(String commentId);
}
