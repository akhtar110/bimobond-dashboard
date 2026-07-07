import '../entities/paginated_page.dart';
import '../entities/user_repost_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityReposts {
  GetUserActivityReposts(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserRepostEntity>> call(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _repository.getUserReposts(userId, page: page, limit: limit);
}
