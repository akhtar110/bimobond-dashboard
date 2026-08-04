import '../../domain/entities/admin_bulk_users_result_entity.dart';
import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../../domain/entities/user_post_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';

class UsersRepositoryImpl implements UsersRepository {
  const UsersRepositoryImpl(this.remoteDataSource);

  final UsersRemoteDataSource remoteDataSource;

  @override
  Future<UsersPageEntity> getUsers({
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
    String? location,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    final result = await remoteDataSource.getUsers(
      page: page,
      limit: limit,
      search: search,
      isVerified: isVerified,
      isBanned: isBanned,
      location: location,
      role: role,
      createdFrom: createdFrom,
      createdTo: createdTo,
    );

    return UsersPageEntity(
      users: result.users,
      total: result.total,
      page: result.page,
      lastPage: result.lastPage,
    );
  }

  @override
  Future<void> blockUser({
    required String userId,
    required String reason,
    DateTime? until,
  }) {
    return remoteDataSource.blockUser(
      userId: userId,
      reason: reason,
      until: until,
    );
  }

  @override
  Future<void> unblockUser(String userId) {
    return remoteDataSource.unblockUser(userId);
  }

  @override
  Future<void> updateUserRoles({
    required String userId,
    required List<UserRole> roles,
  }) {
    return remoteDataSource.updateUserRoles(userId: userId, roles: roles);
  }

  @override
  Future<void> promoteToAdmin(String userId) {
    return remoteDataSource.promoteToAdmin(userId);
  }

  @override
  Future<void> demoteFromAdmin(String userId) {
    return remoteDataSource.demoteFromAdmin(userId);
  }

  @override
  Future<void> deleteUser(String userId) {
    return remoteDataSource.deleteUser(userId);
  }

  @override
  Future<AdminBulkUsersResultEntity> suspendUsers(
    List<String> userIds, {
    required String reason,
    DateTime? until,
  }) {
    return remoteDataSource.suspendUsers(
      userIds,
      reason: reason,
      until: until,
    );
  }

  @override
  Future<AdminBulkUsersResultEntity> activateUsers(List<String> userIds) {
    return remoteDataSource.activateUsers(userIds);
  }

  @override
  Future<AdminBulkUsersResultEntity> deleteUsers(List<String> userIds) {
    return remoteDataSource.deleteUsers(userIds);
  }

  @override
  Future<AdminBulkUsersResultEntity> promoteUsers(List<String> userIds) {
    return remoteDataSource.promoteUsers(userIds);
  }

  @override
  Future<AdminBulkUsersResultEntity> demoteUsers(List<String> userIds) {
    return remoteDataSource.demoteUsers(userIds);
  }

  @override
  Future<AdminBulkUsersResultEntity> bulkUpdateUsers(
    List<String> userIds, {
    required Map<String, dynamic> data,
  }) {
    return remoteDataSource.bulkUpdateUsers(userIds, data: data);
  }

  @override
  Future<AdminBulkUsersResultEntity> bulkUpdateUserRoles(
    List<String> userIds, {
    required List<UserRole> roles,
  }) {
    return remoteDataSource.bulkUpdateUserRoles(userIds, roles: roles);
  }

  @override
  Future<void> verifyUser(String userId) {
    return remoteDataSource.verifyUser(userId);
  }

  @override
  Future<void> unverifyUser(String userId) {
    return remoteDataSource.unverifyUser(userId);
  }

  @override
  Future<void> suspendUser(String userId) {
    return remoteDataSource.suspendUser(userId);
  }

  @override
  Future<void> unsuspendUser(String userId) {
    return remoteDataSource.unsuspendUser(userId);
  }

  @override
  Future<void> banUser(String userId, {String? reason, DateTime? until}) {
    return remoteDataSource.banUser(userId, reason: reason, until: until);
  }

  @override
  Future<void> unbanUser(String userId) {
    return remoteDataSource.unbanUser(userId);
  }

  @override
  Future<void> activateUser(String userId) {
    return remoteDataSource.activateUser(userId);
  }

  @override
  Future<void> deactivateUser(String userId) {
    return remoteDataSource.deactivateUser(userId);
  }

  @override
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) {
    return remoteDataSource.resetUserPassword(
      userId: userId,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> updateAdminUser(
    String userId, {
    required Map<String, dynamic> data,
  }) {
    return remoteDataSource.updateAdminUser(userId, data: data);
  }

  @override
  Future<void> setUserCanPost(String userId, {required bool canPost}) {
    return remoteDataSource.setUserCanPost(userId, canPost: canPost);
  }

  @override
  Future<void> setUserAllowDirectMsgs(String userId, {required bool allow}) {
    return remoteDataSource.setUserAllowDirectMsgs(userId, allow: allow);
  }

  @override
  Future<void> setUserIsPrivate(String userId, {required bool isPrivate}) {
    return remoteDataSource.setUserIsPrivate(userId, isPrivate: isPrivate);
  }

  @override
  Future<void> setUserMessagePermission(
    String userId, {
    required MessagePermission permission,
  }) {
    return remoteDataSource.setUserMessagePermission(
      userId,
      permission: permission,
    );
  }

  @override
  Future<UserDetailEntity> getUserById(String userId) {
    return remoteDataSource.getUserById(userId);
  }

  @override
  Future<UserPostsResponseEntity> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getUserPosts(userId, page: page, limit: limit);
  }

  @override
  Future<UserFollowListPageEntity> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getUserFollowList(
      userId: userId,
      kind: kind,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ForceRemoveFollowResultEntity> forceRemoveFollower({
    required String userId,
    required String followerId,
  }) {
    return remoteDataSource.forceRemoveFollower(
      userId: userId,
      followerId: followerId,
    );
  }
}
