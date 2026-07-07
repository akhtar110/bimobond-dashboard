import '../entities/user_follow_entity.dart';
import '../repositories/users_repository.dart';

class GetUserFollowList {
  const GetUserFollowList(this.repository);

  final UsersRepository repository;

  Future<UserFollowListPageEntity> call({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  }) {
    return repository.getUserFollowList(
      userId: userId,
      kind: kind,
      page: page,
      limit: limit,
    );
  }
}
