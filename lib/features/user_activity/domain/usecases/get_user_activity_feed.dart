import '../entities/paginated_page.dart';
import '../entities/user_activity_item_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityFeed {
  GetUserActivityFeed(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserActivityItemEntity>> call(
    String userId, {
    required int page,
    int limit = 10,
  }) {
    return _repository.getUserActivityFeed(userId, page: page, limit: limit);
  }
}
