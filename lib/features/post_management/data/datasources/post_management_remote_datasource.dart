import 'package:dio/dio.dart';

import '../../domain/entities/comment_entity.dart';import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_engagement_user_item.dart';
import '../models/comment_model.dart';
import '../models/managed_post_model.dart';
import '../models/post_engagement_user_model.dart';

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

  Future<PostEngagementUsersPageEntity> getPostEngagementUsers(
    String postId, {
    required PostEngagementKind kind,
    required int page,
    required int limit,
    String? postAuthorId,
  });
}

class PostManagementRemoteDataSourceImpl
    implements PostManagementRemoteDataSource {
  PostManagementRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ManagedPostModel> getManagedPostById(String postId) async {
    DioException? lastError;
    const paths = ['/posts/admin/', '/posts/'];

    for (final prefix in paths) {
      try {
        final response = await _dio.get('$prefix$postId');
        return _parsePostResponse(response.data);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) continue;
        rethrow;
      }
    }

    throw lastError ?? Exception('Post not found: $postId');
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
    DioException? lastError;
    const paths = ['/posts/admin/', '/posts/'];

    for (final prefix in paths) {
      try {
        final response = await _dio.get(
          '$prefix$postId/comments',
          queryParameters: {'page': page, 'limit': limit},
        );
        return PostCommentsPageModel.fromJson(
          _asMap(response.data),
          limit: limit,
        );
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) continue;
        rethrow;
      }
    }

    throw lastError ?? Exception('Failed to load comments for post $postId');
  }

  @override
  Future<void> deleteCommentAsAdmin(String commentId) async {
    await _dio.delete('/posts/comments/$commentId');
  }

  @override
  Future<PostEngagementUsersPageEntity> getPostEngagementUsers(
    String postId, {
    required PostEngagementKind kind,
    required int page,
    required int limit,
    String? postAuthorId,
  }) async {
    if (kind == PostEngagementKind.mentions) {
      try {
        final pageResult = await _fetchPostEngagementPage(
          postId: postId,
          segment: 'mentions',
          page: page,
          limit: limit,
          parser: (data) => PostEngagementUsersPageModel.fromMentionsJson(
            data,
            limit: limit,
          ),
        );
        if (pageResult.items.isNotEmpty) return pageResult;
      } catch (_) {
        // Per-post mentions endpoint may not exist — fall back below.
      }

      if (postAuthorId != null && postAuthorId.isNotEmpty) {
        return _fetchUserMentionsForPost(
          userId: postAuthorId,
          postId: postId,
          page: page,
          limit: limit,
        );
      }

      return const PostEngagementUsersPageModel(
        items: [],
        page: 1,
        hasMore: false,
      );
    }

    final segment = switch (kind) {
      PostEngagementKind.likes => 'likes',
      PostEngagementKind.views => 'views',
      PostEngagementKind.mentions => 'mentions',
    };

    return _fetchPostEngagementPage(
      postId: postId,
      segment: segment,
      page: page,
      limit: limit,
      parser: (data) => switch (kind) {
        PostEngagementKind.likes => PostEngagementUsersPageModel.fromLikesJson(
            data,
            limit: limit,
          ),
        PostEngagementKind.views => PostEngagementUsersPageModel.fromViewsJson(
            data,
            limit: limit,
          ),
        PostEngagementKind.mentions =>
          PostEngagementUsersPageModel.fromMentionsJson(
            data,
            limit: limit,
          ),
      },
    );
  }

  Future<PostEngagementUsersPageModel> _fetchPostEngagementPage({
    required String postId,
    required String segment,
    required int page,
    required int limit,
    required PostEngagementUsersPageModel Function(Map<String, dynamic> data)
        parser,
  }) async {
    final response = await _fetchEngagementSegment(
      postId: postId,
      segment: segment,
      page: page,
      limit: limit,
    );
    return parser(_asMap(response.data));
  }

  Future<PostEngagementUsersPageModel> _fetchUserMentionsForPost({
    required String userId,
    required String postId,
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/users/$userId/mentions',
      queryParameters: {
        'page': page,
        'limit': limit,
        'type': 'all',
      },
    );
    final data = _asMap(response.data);
    final rawMentions = data['mentions'];
    if (rawMentions is List) {
      final filtered = rawMentions.where((entry) {
        if (entry is! Map) return false;
        final map = Map<String, dynamic>.from(entry);
        if (map['postId']?.toString() == postId) return true;
        final post = map['post'];
        if (post is Map && post['id']?.toString() == postId) return true;
        final comment = map['comment'];
        if (comment is Map) {
          final nestedPost = comment['post'];
          if (nestedPost is Map && nestedPost['id']?.toString() == postId) {
            return true;
          }
        }
        return false;
      }).toList();
      data['mentions'] = filtered;
    }

    return PostEngagementUsersPageModel.fromMentionsJson(data, limit: limit);
  }

  Future<Response<dynamic>> _fetchEngagementSegment({
    required String postId,
    required String segment,
    required int page,
    required int limit,
  }) async {
    final query = {'page': page, 'limit': limit};
    final paths = [
      '/posts/admin/$postId/$segment',
      '/posts/$postId/$segment',
    ];

    DioException? lastError;
    for (final path in paths) {
      try {
        return await _dio.get(path, queryParameters: query);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) continue;
        rethrow;
      }
    }
    throw lastError ?? Exception('Failed to load $segment for post $postId');
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) {
      return {'data': data};
    }
    throw Exception('Invalid engagement response format');
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

