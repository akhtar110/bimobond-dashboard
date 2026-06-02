import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../models/user_detail_model.dart';
import '../models/user_post_model.dart';
import 'package:dio/dio.dart';

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
  Future<void> verifyUser(String userId);
  Future<UserDetailModel> getUserById(String userId);
  Future<UserPostsResponseModel> getUserPosts(String userId, {int page = 1, int limit = 20});
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

  @override
  Future<void> verifyUser(String userId) async {
    await _dio.patch('/users/$userId/verify');
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
}
