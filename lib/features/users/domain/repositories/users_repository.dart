import '../entities/user_entity.dart';
import '../entities/user_detail_entity.dart';
import '../entities/user_post_entity.dart';

abstract class UsersRepository {
  Future<UsersPageEntity> getUsers({
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
  });

  Future<void> blockUser({
    required String userId,
    required String reason,
    required DateTime until,
  });

  Future<void> unblockUser(String userId);

  Future<void> updateUserRoles({
    required String userId,
    required List<UserRole> roles,
  });

  Future<void> promoteToAdmin(String userId);
  Future<void> demoteFromAdmin(String userId);
  Future<void> verifyUser(String userId);
  Future<void> deleteUser(String userId);
  Future<UserDetailEntity> getUserById(String userId);
  Future<UserPostsResponseEntity> getUserPosts(String userId, {int page = 1, int limit = 20});
}
