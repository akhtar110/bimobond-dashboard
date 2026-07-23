import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/admin_bulk_user_action.dart';
import '../../domain/entities/admin_bulk_users_result_entity.dart';
import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../models/admin_bulk_users_result_model.dart';
import '../models/user_detail_model.dart';
import '../models/user_follow_model.dart';
import '../models/user_model.dart';
import '../models/reset_user_password_request_model.dart';
import '../models/user_post_model.dart';

abstract class UsersRemoteDataSource {
  Future<UsersPageModel> getUsers({
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
  Future<void> verifyUser(String userId);
  Future<void> unverifyUser(String userId);
  Future<void> suspendUser(String userId);
  Future<void> unsuspendUser(String userId);
  Future<void> banUser(String userId);
  Future<void> unbanUser(String userId);
  Future<void> activateUser(String userId);
  Future<void> deactivateUser(String userId);
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  });
  Future<void> setUserCanPost(String userId, {required bool canPost});
  Future<void> setUserAllowDirectMsgs(String userId, {required bool allow});
  Future<void> setUserIsPrivate(String userId, {required bool isPrivate});
  Future<void> setUserMessagePermission(
    String userId, {
    required MessagePermission permission,
  });
  Future<UserDetailModel> getUserById(String userId);
  Future<UserPostsResponseModel> getUserPosts(String userId, {int page = 1, int limit = 20});
  Future<UserFollowListPageModel> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  });
}

class UsersPageModel {
  final List<UserModel> users;
  final int total;
  final int page;
  final int lastPage;

  UsersPageModel({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
  });
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final Dio _dio;

  UsersRemoteDataSourceImpl(this._dio);

  @override
  Future<UsersPageModel> getUsers({
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    final response = await _dio.get(
      '/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isVerified != null) 'isVerified': isVerified,
        if (isBanned != null) 'isBanned': isBanned,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data as Map<String, dynamic>;

    print("Data Response $data");

    return UsersPageModel(
      users: (data['users'] as List).map((e) => UserModel.fromJson(e)).toList(),
      total: data['meta']['total'],
      page: data['meta']['page'],
      lastPage: data['meta']['lastPage'],
    );
  }

  @override
  Future<void> blockUser({
    required String userId,
    required String reason,
    required DateTime until,
  }) async {
    await _dio.patch(
      '/users/$userId/ban',
      data: {'reason': reason, 'until': until.toIso8601String()},
    );
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _dio.patch('/users/$userId/unban');
  }

  @override
  Future<void> updateUserRoles({
    required String userId,
    required List<UserRole> roles,
  }) async {
    await _dio.patch(
      '/users/$userId/role',
      data: {'roles': roles.map((e) => e.name.toUpperCase()).toList()},
    );
  }

  @override
  Future<void> promoteToAdmin(String userId) async {
    await _dio.patch('/users/$userId/promote');
  }

  @override
  Future<void> demoteFromAdmin(String userId) async {
    await _dio.patch('/users/$userId/demote');
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _dio.delete('/users/$userId');
  }

  static const _bulkPath = '/users/admin/bulk';

  Future<AdminBulkUsersResultModel> _bulkUsers({
    required List<String> userIds,
    required AdminBulkUserAction action,
    String? reason,
    DateTime? until,
  }) async {
    if (userIds.isEmpty) {
      return AdminBulkUsersResultModel(
        action: action,
        successCount: 0,
        failedCount: 0,
        notFoundCount: 0,
        userIds: const [],
        notFoundIds: const [],
      );
    }

    final body = <String, dynamic>{
      'userIds': userIds,
      'action': action.apiValue,
    };

    if (action == AdminBulkUserAction.ban) {
      body['reason'] = reason ?? 'Bulk admin action';
      if (until != null) {
        body['until'] = until.toUtc().toIso8601String();
      }
    }

    final response = await _dio.post(_bulkPath, data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AdminBulkUsersResultModel.fromJson(data, action);
    }

    return _allSucceeded(userIds, action);
  }

  AdminBulkUsersResultModel _allSucceeded(
    List<String> userIds,
    AdminBulkUserAction action,
  ) {
    return AdminBulkUsersResultModel(
      action: action,
      successCount: userIds.length,
      failedCount: 0,
      notFoundCount: 0,
      userIds: userIds,
      notFoundIds: const [],
    );
  }

  @override
  Future<AdminBulkUsersResultEntity> suspendUsers(
    List<String> userIds, {
    required String reason,
    DateTime? until,
  }) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.ban);
    }
    try {
      return await _bulkUsers(
        userIds: userIds,
        action: AdminBulkUserAction.ban,
        reason: reason,
        until: until ?? DateTime.now().add(const Duration(days: 3650)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        rethrow;
      }
      final banUntil =
          until ?? DateTime.now().add(const Duration(days: 3650));
      for (final id in userIds) {
        await blockUser(userId: id, reason: reason, until: banUntil);
      }
      return _allSucceeded(userIds, AdminBulkUserAction.ban);
    }
  }

  @override
  Future<AdminBulkUsersResultEntity> activateUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.unban);
    }
    try {
      return await _bulkUsers(
        userIds: userIds,
        action: AdminBulkUserAction.unban,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        rethrow;
      }
      for (final id in userIds) {
        await unblockUser(id);
      }
      return _allSucceeded(userIds, AdminBulkUserAction.unban);
    }
  }

  @override
  Future<AdminBulkUsersResultEntity> deleteUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.delete);
    }
    try {
      return await _bulkUsers(
        userIds: userIds,
        action: AdminBulkUserAction.delete,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        rethrow;
      }
      for (final id in userIds) {
        await deleteUser(id);
      }
      return _allSucceeded(userIds, AdminBulkUserAction.delete);
    }
  }

  @override
  Future<AdminBulkUsersResultEntity> promoteUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.promote);
    }
    try {
      return await _bulkUsers(
        userIds: userIds,
        action: AdminBulkUserAction.promote,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        rethrow;
      }
      for (final id in userIds) {
        await promoteToAdmin(id);
      }
      return _allSucceeded(userIds, AdminBulkUserAction.promote);
    }
  }

  @override
  Future<AdminBulkUsersResultEntity> demoteUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.demote);
    }
    try {
      return await _bulkUsers(
        userIds: userIds,
        action: AdminBulkUserAction.demote,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        rethrow;
      }
      for (final id in userIds) {
        await demoteFromAdmin(id);
      }
      return _allSucceeded(userIds, AdminBulkUserAction.demote);
    }
  }

  @override
  Future<void> verifyUser(String userId) async {
    await _dio.patch('/users/$userId/verify');
  }

  @override
  Future<void> unverifyUser(String userId) async {
    await _dio.patch('/users/$userId/unverify');
  }

  @override
  Future<void> suspendUser(String userId) async {
    await blockUser(
      userId: userId,
      reason: 'Suspended by admin',
      until: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    await unblockUser(userId);
  }

  @override
  Future<void> banUser(String userId) async {
    await blockUser(
      userId: userId,
      reason: 'Banned by admin',
      until: DateTime.now().add(const Duration(days: 3650)),
    );
  }

  @override
  Future<void> unbanUser(String userId) async {
    await unblockUser(userId);
  }

  @override
  Future<void> activateUser(String userId) async {
    await unblockUser(userId);
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await blockUser(
      userId: userId,
      reason: 'Deactivated by admin',
      until: DateTime.now().add(const Duration(days: 3650)),
    );
  }

  @override
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    await _dio.patch(
      '/users/admin/$userId/password',
      data: ResetUserPasswordRequestModel(newPassword: newPassword).toJson(),
    );
  }

  @override
  Future<void> setUserCanPost(String userId, {required bool canPost}) async {
    await _dio.patch(
      '/users/$userId/admin/settings',
      data: {'canPost': canPost},
    );
  }

  @override
  Future<void> setUserAllowDirectMsgs(
    String userId, {
    required bool allow,
  }) async {
    await _dio.patch(
      '/users/$userId/admin/settings',
      data: {'allowDirectMsgs': allow},
    );
  }

  @override
  Future<void> setUserIsPrivate(String userId, {required bool isPrivate}) async {
    await _dio.patch(
      '/users/$userId/admin/settings',
      data: {'isPrivate': isPrivate},
    );
  }

  @override
  Future<void> setUserMessagePermission(
    String userId, {
    required MessagePermission permission,
  }) async {
    await _dio.patch(
      '/users/$userId/admin/settings',
      data: {'messagePermission': permission.apiValue},
    );
  }

  @override
  Future<UserDetailModel> getUserById(String userId) async {
    final response = await _dio.get('/users/$userId');
    print('response data for user id $userId ${response.data}');
    
    return UserDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserPostsResponseModel> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get('/posts/admin/all', queryParameters: {
      'userId': userId,
      'page': page,
      'limit': limit,
    });
    print('posts response data for user id $userId ${response.data}');
    
    return UserPostsResponseModel.fromJson(response.data);
  }

  @override
  Future<UserFollowListPageModel> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  }) async {
    final segment =
        kind == UserFollowListKind.followers ? 'followers' : 'following';
    final response = await _dio.get(
      '/users/$userId/$segment',
      queryParameters: {'page': page, 'limit': limit},
    );

    return UserFollowListPageModel.fromJson(
      response.data as Map<String, dynamic>,
      kind,
    );
  }
}
