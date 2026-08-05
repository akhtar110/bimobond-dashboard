import '../entities/admin_bulk_users_result_entity.dart';
import '../entities/message_permission.dart';
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
    bool? isOnline,
    String? location,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? city,
    String? region,
    String? country,
  });

  Future<void> blockUser({
    required String userId,
    required String reason,
    DateTime? until,
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
  Future<void> banUser(String userId, {String? reason, DateTime? until});
  Future<void> unbanUser(String userId);
  Future<void> activateUser(String userId);
  Future<void> deactivateUser(String userId);
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  });
  Future<void> updateAdminUser(
    String userId, {
    required Map<String, dynamic> data,
  });
  Future<void> setUserCanPost(String userId, {required bool canPost});
  Future<void> setUserAllowDirectMsgs(String userId, {required bool allow});
  Future<void> setUserIsPrivate(String userId, {required bool isPrivate});
  Future<void> setUserMessagePermission(
    String userId, {
    required MessagePermission permission,
  });
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
  Future<AdminBulkUsersResultEntity> bulkUpdateUsers(
    List<String> userIds, {
    required Map<String, dynamic> data,
  });
  Future<AdminBulkUsersResultEntity> bulkUpdateUserRoles(
    List<String> userIds, {
    required List<UserRole> roles,
  });
  Future<UserDetailEntity> getUserById(String userId);
  Future<UserPostsResponseEntity> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  });
  Future<UserFollowListPageEntity> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  });
  Future<ForceRemoveFollowResultEntity> forceRemoveFollower({
    required String userId,
    required String followerId,
  });
}
