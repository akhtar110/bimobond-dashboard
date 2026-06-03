import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/post_filters.dart';
import '../models/post_model.dart';

abstract class PostsRemoteDataSource {
  Future<PostsPageModel> getAllPosts({
    required int page,
    required int limit,
    required PostFilters filters,
  });
}

class PostsRemoteDataSourceImpl implements PostsRemoteDataSource {
  const PostsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PostsPageModel> getAllPosts({
    required int page,
    required int limit,
    required PostFilters filters,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': filters.sort ?? PostFilters.defaultSort,
    };

    // The API expects a category slug/label (e.g. "music"), not a UUID.
    final categorySlug = filters.categorySlug?.trim();
    if (categorySlug != null && categorySlug.isNotEmpty) {
      params['category'] = categorySlug;
    }

    final search = filters.search?.trim();
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final type = filters.type?.trim();
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }

    if (filters.isAuctionable == true) {
      params['isAuctionable'] = 'true';
    }

    final response = await _dio.get(
      '/posts/admin/all',
      queryParameters: params,
    );

    final raw = response.data as Map<String, dynamic>;
    final result = PostsPageModel.fromJson(raw);

    if (kDebugMode) {
      debugPrint('[Posts] fetched ${result.posts.length} posts '
          '(page ${result.currentPage}/${result.lastPage})');
      for (final p in result.posts.take(3)) {
        debugPrint('  post ${p.id}: type=${p.type} '
            'thumbnailUrl=${p.thumbnailUrl} '
            'videoUrl=${p.videoUrl} '
            'media.length=${p.media.length}');
        for (final m in p.media) {
          debugPrint('    media url=${m.url} type=${m.mediaType}');
        }
      }
    }

    return result;
  }
}
