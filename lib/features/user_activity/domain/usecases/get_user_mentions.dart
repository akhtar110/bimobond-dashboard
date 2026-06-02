import '../entities/paginated_page.dart';
import '../entities/user_mention_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserMentions {
  GetUserMentions(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserMentionEntity>> call(
    String userId, {
    required int page,
    int limit = 10,
  }) {
    return _repository.getUserMentions(userId, page: page, limit: limit);
  }
}
