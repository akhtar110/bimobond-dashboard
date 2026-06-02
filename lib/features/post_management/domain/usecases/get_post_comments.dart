import '../entities/comment_entity.dart';
import '../repositories/post_management_repository.dart';

class GetPostComments {
  const GetPostComments(this.repository);

  final PostManagementRepository repository;

  Future<PostCommentsPageEntity> call(
    String postId, {
    int page = 1,
    int limit = 20,
  }) =>
      repository.getPostComments(postId, page: page, limit: limit);
}
