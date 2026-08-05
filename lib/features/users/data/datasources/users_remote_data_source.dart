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
  Future<UserDetailModel> getUserById(String userId);
  Future<UserPostsResponseModel> getUserPosts(String userId, {int page = 1, int limit = 20});
  Future<UserFollowListPageModel> getUserFollowList({
    required String userId,
    required UserFollowListKind kind,
    int page = 1,
    int limit = 20,
  });
  Future<ForceRemoveFollowResultModel> forceRemoveFollower({
    required String userId,
    required String followerId,
  });
}

class UsersPageModel {
  final List<UserModel> users;
  final int total;
  final int page;
  final int lastPage;
  final int onlineCount;
  final int verifiedCount;
  final int bannedCount;

  UsersPageModel({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
    this.onlineCount = 0,
    this.verifiedCount = 0,
    this.bannedCount = 0,
  });
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final Dio _dio;

  UsersRemoteDataSourceImpl(this._dio);

  List<UserModel> _applyClientSideFilters(
    List<UserModel> inputUsers, {
    bool? isVerified,
    bool? isBanned,
    bool? isOnline,
    String? role,
    String? location,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) {
    var users = List<UserModel>.from(inputUsers);
    if (isVerified != null) {
      users = users.where((u) => u.isVerified == isVerified).toList();
    }
    if (isBanned != null) {
      users = users.where((u) => u.isBanned == isBanned).toList();
    }
    if (isOnline != null) {
      users = users.where((u) => u.isOnline == isOnline).toList();
    }
    if (role != null && role.isNotEmpty) {
      final roleLower = role.toLowerCase();
      users = users.where((u) {
        if (roleLower == 'user') {
          return !u.roles.includesStaff;
        } else if (roleLower == 'admin') {
          return u.roles.includesAdmin;
        } else if (roleLower == 'moderator') {
          return u.roles.includesModerator;
        } else if (roleLower == 'superadmin') {
          return u.roles.any((r) => r == UserRole.superAdmin);
        }
        return u.roles.any((r) => r.name.toLowerCase() == roleLower);
      }).toList();
    }
    if (location != null && location.isNotEmpty) {
      final locLower = location.toLowerCase();
      users = users.where((u) {
        final city = (u.city ?? '').toLowerCase();
        final region = (u.region ?? '').toLowerCase();
        final country = (u.country ?? '').toLowerCase();
        return city.contains(locLower) || region.contains(locLower) || country.contains(locLower);
      }).toList();
    }
    if (createdFrom != null) {
      final startOfDay = DateTime(createdFrom.year, createdFrom.month, createdFrom.day, 0, 0, 0);
      users = users.where((u) => u.createdAt != null && (u.createdAt!.isAfter(startOfDay) || u.createdAt!.isAtSameMomentAs(startOfDay))).toList();
    }
    if (createdTo != null) {
      final endOfDay = DateTime(createdTo.year, createdTo.month, createdTo.day, 23, 59, 59, 999);
      users = users.where((u) => u.createdAt != null && (u.createdAt!.isBefore(endOfDay) || u.createdAt!.isAtSameMomentAs(endOfDay))).toList();
    }
    return users;
  }

  @override
  Future<UsersPageModel> getUsers({
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
    bool? isOnline,
    String? location,
    String? city,
    String? region,
    String? country,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    final authHeaders = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    Future<Response<dynamic>> requestEndpoint(Map<String, dynamic> params) async {
      try {
        return await _dio.get(
          '/users/admin/online',
          queryParameters: params,
          options: Options(headers: authHeaders),
        );
      } catch (e) {
        return await _dio.get(
          '/users',
          queryParameters: params,
          options: Options(headers: authHeaders),
        );
      }
    }

    final hasActiveFilters = isVerified != null ||
        isBanned != null ||
        isOnline != null ||
        (role != null && role.isNotEmpty) ||
        (location != null && location.isNotEmpty) ||
        createdFrom != null ||
        createdTo != null;

    final accumulatedMatchingUsers = <UserModel>[];
    int currentServerPage = hasActiveFilters ? 1 : page;
    int serverLastPage = page;
    int serverTotal = 0;
    int onlineCount = 0;
    int verifiedCount = 0;
    int bannedCount = 0;
    final targetNeededCount = page * limit;

    while (currentServerPage <= serverLastPage &&
        (!hasActiveFilters || accumulatedMatchingUsers.length < targetNeededCount)) {
      final queryParams = <String, dynamic>{
        'page': currentServerPage,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await requestEndpoint(queryParams);
      final data = response.data as Map<String, dynamic>;
      onlineCount = (data['onlineCount'] as num?)?.toInt() ?? onlineCount;
      verifiedCount = (data['verifiedCount'] as num?)?.toInt() ?? verifiedCount;
      bannedCount = (data['bannedCount'] as num?)?.toInt() ?? bannedCount;

      final meta = data['meta'] as Map<String, dynamic>?;
      if (meta != null) {
        serverLastPage = (meta['lastPage'] as num?)?.toInt() ?? currentServerPage;
        serverTotal = (meta['total'] as num?)?.toInt() ?? 0;
      }

      final rawUsers = (data['users'] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final rawCounts = map['_count'] ?? map['counts'];
        final counts = rawCounts is Map ? Map<String, dynamic>.from(rawCounts) : null;
        return UserModel.fromJson(map, counts: counts);
      }).toList();

      final filtered = _applyClientSideFilters(
        rawUsers,
        isVerified: isVerified,
        isBanned: isBanned,
        isOnline: isOnline,
        role: role,
        location: location,
        createdFrom: createdFrom,
        createdTo: createdTo,
      );

      accumulatedMatchingUsers.addAll(filtered);

      if (!hasActiveFilters) break;
      if (currentServerPage >= page + 10) break;

      currentServerPage++;
    }

    List<UserModel> users;
    if (hasActiveFilters) {
      final startIndex = (page - 1) * limit;
      users = accumulatedMatchingUsers.skip(startIndex).take(limit).toList();
    } else {
      users = accumulatedMatchingUsers;
    }

    // `/users` often returns denormalized totalLikes as 0. Backfill from
    // user-reports when available (uses counts.postLikes / totalLikes).
    if (users.any((u) => u.totalLikes <= 0 && u.postCount > 0)) {
      users = await _backfillTotalLikes(
        users,
        page: page,
        limit: limit,
        search: search,
        isVerified: isVerified,
        isBanned: isBanned,
      );
    }

    final finalTotal = hasActiveFilters ? accumulatedMatchingUsers.length : serverTotal;
    final finalLastPage = hasActiveFilters
        ? ((accumulatedMatchingUsers.length / limit).ceil()).clamp(1, 9999)
        : serverLastPage;

    final effectiveVerified = verifiedCount > 0
        ? verifiedCount
        : accumulatedMatchingUsers.where((u) => u.isVerified).length;
    final effectiveBanned = bannedCount > 0
        ? bannedCount
        : accumulatedMatchingUsers.where((u) => u.isBanned).length;

    return UsersPageModel(
      users: users,
      total: finalTotal,
      page: page,
      lastPage: finalLastPage,
      onlineCount: onlineCount,
      verifiedCount: effectiveVerified,
      bannedCount: effectiveBanned,
    );
  }

  Future<List<UserModel>> _backfillTotalLikes(
    List<UserModel> users, {
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
  }) async {
    try {
      final response = await _dio.get(
        '/user-reports/admin/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (isVerified != null) 'isVerified': isVerified,
          if (isBanned != null) 'isBanned': isBanned,
        },
      );

      final raw = response.data;
      final list = raw is Map
          ? (raw['data'] ?? raw['users'] ?? raw['items'])
          : raw;
      if (list is! List) return users;

      final likesById = <String, int>{};
      for (final item in list) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final counts = map['counts'] ?? map['_count'];
        final countsMap =
            counts is Map ? Map<String, dynamic>.from(counts) : null;
        final likes = UserModel.readInt(
              map['totalLikes'] ??
                  map['likesCount'] ??
                  map['postLikes'] ??
                  countsMap?['postLikes'] ??
                  countsMap?['totalLikes'] ??
                  countsMap?['likes'],
            ) ??
            0;
        if (likes > 0) likesById[id] = likes;
      }

      if (likesById.isEmpty) return users;

      return users
          .map(
            (u) => likesById.containsKey(u.id) && likesById[u.id]! > u.totalLikes
                ? u.copyWith(totalLikes: likesById[u.id])
                : u,
          )
          .toList();
    } catch (_) {
      // Reports endpoint may be unavailable for some roles; keep /users values.
      return users;
    }
  }

  @override
  Future<void> blockUser({
    required String userId,
    required String reason,
    DateTime? until,
  }) async {
    final body = <String, dynamic>{
      'reason': reason.trim().isEmpty ? 'Banned by admin' : reason.trim(),
    };
    if (until != null) {
      body['until'] = until.toUtc().toIso8601String();
    }
    await _dio.patch('/users/$userId/ban', data: body);
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
    // Legacy Role enum only — never send SUPER_ADMIN.
    final legacyRoles = roles
        .map((e) => switch (e) {
              UserRole.admin => 'ADMIN',
              UserRole.superAdmin => 'ADMIN',
              UserRole.moderator => 'MODERATOR',
              UserRole.user => 'USER',
            })
        .toSet()
        .toList();
    await _dio.patch(
      '/users/$userId/role',
      data: {'roles': legacyRoles},
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
    Map<String, dynamic>? data,
    List<String>? roles,
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
      body['reason'] = (reason == null || reason.trim().isEmpty)
          ? 'Bulk admin action'
          : reason.trim();
      if (until != null) {
        body['until'] = until.toUtc().toIso8601String();
      }
    }

    if (action == AdminBulkUserAction.update) {
      if (data == null || data.isEmpty) {
        throw ArgumentError('Bulk UPDATE requires a non-empty data object');
      }
      body['data'] = data;
    }

    if (action == AdminBulkUserAction.updateRoles) {
      if (roles == null || roles.isEmpty) {
        throw ArgumentError('Bulk UPDATE_ROLES requires a non-empty roles list');
      }
      body['roles'] = roles;
    }

    final response = await _dio.post(_bulkPath, data: body);
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      return AdminBulkUsersResultModel.fromJson(responseData, action);
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
  Future<AdminBulkUsersResultEntity> bulkUpdateUsers(
    List<String> userIds, {
    required Map<String, dynamic> data,
  }) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.update);
    }
    return _bulkUsers(
      userIds: userIds,
      action: AdminBulkUserAction.update,
      data: data,
    );
  }

  @override
  Future<AdminBulkUsersResultEntity> bulkUpdateUserRoles(
    List<String> userIds, {
    required List<UserRole> roles,
  }) async {
    if (userIds.isEmpty) {
      return _allSucceeded(userIds, AdminBulkUserAction.updateRoles);
    }
    final legacyRoles = roles
        .map((e) => switch (e) {
              UserRole.admin => 'ADMIN',
              UserRole.superAdmin => 'ADMIN',
              UserRole.moderator => 'MODERATOR',
              UserRole.user => 'USER',
            })
        .toSet()
        .toList();
    return _bulkUsers(
      userIds: userIds,
      action: AdminBulkUserAction.updateRoles,
      roles: legacyRoles,
    );
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
  Future<void> banUser(
    String userId, {
    String? reason,
    DateTime? until,
  }) async {
    await blockUser(
      userId: userId,
      reason: reason ?? 'Banned by admin',
      until: until,
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
  Future<void> updateAdminUser(
    String userId, {
    required Map<String, dynamic> data,
  }) async {
    if (data.isEmpty) return;
    await _dio.patch('/users/admin/$userId', data: data);
  }

  @override
  Future<void> setUserCanPost(String userId, {required bool canPost}) async {
    await updateAdminUser(userId, data: {'canPost': canPost});
  }

  @override
  Future<void> setUserAllowDirectMsgs(
    String userId, {
    required bool allow,
  }) async {
    await updateAdminUser(userId, data: {'allowDirectMsgs': allow});
  }

  @override
  Future<void> setUserIsPrivate(String userId, {required bool isPrivate}) async {
    await updateAdminUser(userId, data: {'isPrivate': isPrivate});
  }

  @override
  Future<void> setUserMessagePermission(
    String userId, {
    required MessagePermission permission,
  }) async {
    await updateAdminUser(
      userId,
      data: {'messagePermission': permission.apiValue},
    );
  }

  @override
  Future<UserDetailModel> getUserById(String userId) async {
    final response = await _dio.get('/users/$userId');
    return UserDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserPostsResponseModel> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get('/posts/admin/all', queryParameters: {
      'userId': userId,
      'page': page,
      'limit': limit,
    });
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

  @override
  Future<ForceRemoveFollowResultModel> forceRemoveFollower({
    required String userId,
    required String followerId,
  }) async {
    final response = await _dio.delete(
      '/users/admin/$userId/followers/$followerId',
    );
    return ForceRemoveFollowResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
