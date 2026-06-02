import '../../../users/domain/entities/user_post_entity.dart';
import '../entities/paginated_page.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityPosts {
  GetUserActivityPosts(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserPostEntity>> call(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _repository.getUserPosts(userId, page: page, limit: limit);
}
