import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_detail_entity.dart';
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
  }) async {
    final result = await remoteDataSource.getUsers(
      page: page,
      limit: limit,
      search: search,
      isVerified: isVerified,
      isBanned: isBanned,
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
    required DateTime until,
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
  Future<void> verifyUser(String userId) {
    return remoteDataSource.verifyUser(userId);
  }

  @override
  Future<UserDetailEntity> getUserById(String userId) {
    return remoteDataSource.getUserById(userId);
  }

  @override
  Future<UserPostsResponseEntity> getUserPosts(String userId, {int page = 1, int limit = 20}) {
    return remoteDataSource.getUserPosts(userId, page: page, limit: limit);
  }
}
