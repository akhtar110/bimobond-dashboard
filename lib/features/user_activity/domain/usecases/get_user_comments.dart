import '../entities/paginated_page.dart';
import '../entities/user_comment_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserComments {
  GetUserComments(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserCommentEntity>> call(
    String userId, {
    required int page,
    int limit = 10,
  }) {
    return _repository.getUserComments(userId, page: page, limit: limit);
  }
}
