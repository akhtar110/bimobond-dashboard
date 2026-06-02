import 'package:dio/dio.dart';

import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../models/comment_model.dart';
import '../models/managed_post_model.dart';

abstract class PostManagementRemoteDataSource {
  Future<ManagedPostModel> getManagedPostById(String postId);
  Future<ManagedPostModel> updateManagedPost(
    String postId,
    ManagedPostUpdateData data,
  );
  Future<void> deleteManagedPost(String postId);

  // ── NEW admin actions ──────────────────────────────────────
  Future<ManagedPostModel> updatePostDetails(
    String postId, {
    String? description,
    String? category,
  });
  Future<ManagedPostModel> hidePost(String postId);
  Future<ManagedPostModel> banPost(String postId);
  Future<ManagedPostModel> updatePostStatus(String postId, String status);

  Future<PostCommentsPageEntity> getPostComments(
    String postId, {
    required int page,
    required int limit,
  });

  Future<void> deleteCommentAsAdmin(String commentId);
}

class PostManagementRemoteDataSourceImpl
    implements PostManagementRemoteDataSource {
  PostManagementRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ManagedPostModel> getManagedPostById(String postId) async {
    final response = await _dio.get('/posts/admin/$postId');
    return _parsePostResponse(response.data);
  }

  @override
  Future<ManagedPostModel> updateManagedPost(
    String postId,
    ManagedPostUpdateData data,
  ) async {
    final response = await _dio.patch(
      '/posts/admin/$postId',
      data: ManagedPostModel.updatePayload(data),
    );
    return _parsePostResponse(response.data);
  }

  @override
  Future<void> deleteManagedPost(String postId) async {
    await _dio.delete('/posts/admin/$postId');
  }

  @override
  Future<ManagedPostModel> updatePostDetails(
    String postId, {
    String? description,
    String? category,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    final response = await _dio.patch('/posts/admin/$postId', data: body);
    return _parsePostResponse(response.data);
  }

  @override
  Future<ManagedPostModel> hidePost(String postId) async {
    final response = await _dio.patch('/posts/admin/$postId/hide');
    return _parsePostResponse(response.data);
  }

  @override
  Future<ManagedPostModel> banPost(String postId) async {
    final response = await _dio.patch('/posts/admin/$postId/ban');
    return _parsePostResponse(response.data);
  }

  @override
  Future<ManagedPostModel> updatePostStatus(
    String postId,
    String status,
  ) async {
    final response = await _dio.patch(
      '/posts/admin/$postId/status',
      data: {'status': status},
    );
    return _parsePostResponse(response.data);
  }

  @override
  Future<PostCommentsPageEntity> getPostComments(
    String postId, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/posts/$postId/comments',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    return PostCommentsPageModel.fromJson(data, limit: limit);
  }

  @override
  Future<void> deleteCommentAsAdmin(String commentId) async {
    await _dio.delete('/posts/comments/$commentId');
  }

  ManagedPostModel _parsePostResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['post'] is Map<String, dynamic>
          ? data['post'] as Map<String, dynamic>
          : data;
      return ManagedPostModel.fromJson(payload);
    }
    throw Exception('Invalid post response format');
  }
}
