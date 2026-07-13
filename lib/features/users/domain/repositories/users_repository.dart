import '../entities/admin_bulk_users_result_entity.dart';
import '../entities/user_detail_entity.dart';
import '../entities/user_entity.dart';
import '../entities/user_follow_entity.dart';
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
  Future<void> unverifyUser(String userId);
  Future<void> suspendUser(String userId);
  Future<void> unsuspendUser(String userId);
  Future<void> banUser(String userId);
  Future<void> unbanUser(String userId);
  Future<void> activateUser(String userId);
  Future<void> deactivateUser(String userId);
  Future<void> resetUserPassword(String userId);
  Future<void> setUserCanPost(String userId, {required bool canPost});
  Future<void> setUserAllowDirectMsgs(String userId, {required bool allow});
  Future<void> deleteUser(String userId);
  Future<AdminBulkUsersResultEntity> suspendUsers(
    List<String> userIds, {
    required String reason,
    DateTime? until,
  });
  Future<AdminBulkUsersResultEntity> activateUsers(List<String> userIds);
  Future<AdminBulkUsersResultEntity> deleteUsers(List<String> userIds);
  Future<AdminBulkUsersResultEntity> promoteUsers(List<String> userIds);
  Future<AdminBulkUsersResultEntity> demoteUsers(List<String> userIds);
  Future<UserDetailEntity> getUserById(String userId);
  Future<UserPostsResponseEntity> getUserPosts(String userId, {int page = 1, int limit = 20});
  Future<UserFollowListPageEntity> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  });
}
