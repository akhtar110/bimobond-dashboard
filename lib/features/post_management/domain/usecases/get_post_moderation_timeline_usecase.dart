import '../entities/post_moderation_entities.dart';
import '../repositories/post_management_repository.dart';

class GetPostModerationTimeline {
  const GetPostModerationTimeline(this.repository);

  final PostManagementRepository repository;

  Future<PostModerationTimelinePage> call(
    String postId, {
    int page = 1,
    int limit = 20,
  }) =>
      repository.getPostModerationTimeline(
        postId,
        page: page,
        limit: limit,
      );
}
