import '../entities/paginated_page.dart';
import '../entities/user_like_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserLikes {
  GetUserLikes(this._repository);

  final UserActivityRepository _repository;

  /// [type] — `'made'` = likes this user gave to other posts;
  ///          `'received'` = likes others gave to this user's posts (default).
  Future<PaginatedPage<UserLikeEntity>> call(
    String userId, {
    required int page,
    int limit = 10,
    String type = 'received',
  }) {
    return _repository.getUserLikes(
      userId,
      page: page,
      limit: limit,
      type: type,
    );
  }
}
