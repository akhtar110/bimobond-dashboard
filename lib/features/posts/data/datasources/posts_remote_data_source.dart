import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/post_filters.dart';
import '../../presentation/utils/post_date_format.dart';
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
      'detail': 1,
    };
    final sort = filters.sort ?? PostFilters.defaultSort;
    params['sort'] = PostFilters.apiSortValue(sort);

    // Location radius is applied client-side after hydrating author/profile
    // coordinates — feed posts often lack `locationId` on the API payload.
    final categoryId = filters.categoryId?.trim();
    if (categoryId != null && categoryId.isNotEmpty) {
      params['categoryId'] = categoryId;
    }

    final search = filters.search?.trim();
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final userId = filters.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      params['userId'] = userId;
      if (kDebugMode) {
        debugPrint('[Posts] filtering by userId=$userId');
      }
    }

    _appendCreatedAtParams(params, filters);

    final type = filters.type?.trim();
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }

    if (filters.isAuctionable == true) {
      params['isAuctionable'] = 'true';
    }

    if (filters.isStory == true) {
      params['isStory'] = 'true';
    }

    if (filters.isAd == true) {
      params['isAd'] = 'true';
    }

    final status = filters.status?.trim();
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }

    final privacyStatus = filters.privacyStatus?.trim();
    if (privacyStatus != null && privacyStatus.isNotEmpty) {
      params['privacyStatus'] = privacyStatus;
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

  /// Admin feed date filters. Avoid `from`/`to` — `from` is [FeedFromSource] on
  /// the base DTO and causes 400 when sent as a date string.
  void _appendCreatedAtParams(
    Map<String, dynamic> params,
    PostFilters filters,
  ) {
    final from = filters.createdFrom;
    final to = filters.createdTo;
    if (from == null && to == null) return;

    if (from != null &&
        to != null &&
        _sameCalendarDay(from, to)) {
      params['date'] = formatPostApiDate(from);
      return;
    }

    if (from != null) {
      params['createdFrom'] = formatPostApiDate(from);
    }
    if (to != null) {
      params['createdTo'] = formatPostApiDate(to);
    }
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
