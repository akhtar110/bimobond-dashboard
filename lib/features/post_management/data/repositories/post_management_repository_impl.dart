import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/managed_post_author_enrichment.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_engagement_user_item.dart';
import '../../domain/repositories/post_management_repository.dart';
import '../datasources/post_management_remote_datasource.dart';

class PostManagementRepositoryImpl implements PostManagementRepository {
  const PostManagementRepositoryImpl(this.remoteDataSource);

  final PostManagementRemoteDataSource remoteDataSource;

  @override
  Future<ManagedPostEntity> getManagedPostById(String postId) async {
    final post = await remoteDataSource.getManagedPostById(postId);
    return hydrateManagedPostMedia(enrichManagedPostAuthor(post));
  }

  @override
  Future<ManagedPostEntity> updateManagedPost(
    String postId,
    ManagedPostUpdateData data,
  ) {
    return remoteDataSource.updateManagedPost(postId, data);
  }

  @override
  Future<void> deleteManagedPost(String postId) {
    return remoteDataSource.deleteManagedPost(postId);
  }

  @override
  Future<ManagedPostEntity> updatePostDetails(
    String postId, {
    String? description,
    String? category,
  }) {
    return remoteDataSource.updatePostDetails(
      postId,
      description: description,
      category: category,
    );
  }

  @override
  Future<ManagedPostEntity> hidePost(String postId) {
    return remoteDataSource.hidePost(postId);
  }

  @override
  Future<ManagedPostEntity> banPost(String postId) {
    return remoteDataSource.banPost(postId);
  }

  @override
  Future<ManagedPostEntity> updatePostStatus(String postId, String status) {
    return remoteDataSource.updatePostStatus(postId, status);
  }

  @override
  Future<PostCommentsPageEntity> getPostComments(
    String postId, {
    required int page,
    required int limit,
  }) {
    return remoteDataSource.getPostComments(
      postId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<void> deleteCommentAsAdmin(String commentId) {
    return remoteDataSource.deleteCommentAsAdmin(commentId);
  }

  @override
  Future<PostEngagementUsersPageEntity> getPostEngagementUsers(
    String postId, {
    required PostEngagementKind kind,
    required int page,
    required int limit,
    String? postAuthorId,
  }) {
    return remoteDataSource.getPostEngagementUsers(
      postId,
      kind: kind,
      page: page,
      limit: limit,
      postAuthorId: postAuthorId,
    );
  }
}
