import '../entities/user_follow_entity.dart';
import '../repositories/users_repository.dart';

class ForceRemoveFollowerParams {
  const ForceRemoveFollowerParams({
    required this.userId,
    required this.followerId,
  });

  /// Profile being followed (`followingId`).
  final String userId;

  /// User who follows them (`followerId`).
  final String followerId;
}

class ForceRemoveFollower {
  const ForceRemoveFollower(this._repository);

  final UsersRepository _repository;

  Future<ForceRemoveFollowResultEntity> call(ForceRemoveFollowerParams params) {
    return _repository.forceRemoveFollower(
      userId: params.userId,
      followerId: params.followerId,
    );
  }
}
