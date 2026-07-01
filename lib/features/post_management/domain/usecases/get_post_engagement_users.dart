import '../entities/post_engagement_user_item.dart';
import '../repositories/post_management_repository.dart';

class GetPostEngagementUsers {
  const GetPostEngagementUsers(this._repository);

  final PostManagementRepository _repository;

  Future<PostEngagementUsersPageEntity> call(
    String postId, {
    required PostEngagementKind kind,
    required int page,
    required int limit,
    String? postAuthorId,
  }) {
    return _repository.getPostEngagementUsers(
      postId,
      kind: kind,
      page: page,
      limit: limit,
      postAuthorId: postAuthorId,
    );
  }
}
