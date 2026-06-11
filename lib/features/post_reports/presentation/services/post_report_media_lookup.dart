import 'package:dio/dio.dart';

import '../../../posts/data/models/post_model.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/entities/post_media_entity.dart';
import '../../domain/entities/post_report_entities.dart';
import '../../domain/usecases/get_post_report_detail.dart';

/// Resolves post-report list thumbnails when the list API omits [PostMediaEntity].
class PostReportMediaLookup {
  PostReportMediaLookup(this._getDetail, this._dio);

  final GetPostReportDetail _getDetail;
  final Dio _dio;

  final _cache = <String, String?>{};
  final _inFlight = <String, Future<String?>>{};

  Future<String?> previewUrlFor(PostReportListItem post) async {
    final immediate = post.imagePreviewUrl;
    if (immediate != null && immediate.isNotEmpty) {
      _cache[post.id] = immediate;
      return immediate;
    }

    final cached = _cache[post.id];
    if (cached != null && cached.isNotEmpty) return cached;
    if (_cache.containsKey(post.id)) return cached;

    _inFlight[post.id] ??= _resolve(post.id);
    try {
      final url = await _inFlight[post.id]!;
      _cache[post.id] = url;
      return url;
    } finally {
      _inFlight.remove(post.id);
    }
  }

  Future<String?> _resolve(String postId) async {
    final fromReportDetail = await _fromPostReportDetail(postId);
    if (fromReportDetail != null && fromReportDetail.isNotEmpty) {
      return fromReportDetail;
    }
    return _fromPostsAdminFeed(postId);
  }

  Future<String?> _fromPostReportDetail(String postId) async {
    try {
      final detail = await _getDetail(
        postId: postId,
        query: const ReportPeriodQuery(days: 30),
      );
      return detail.post.imagePreviewUrl;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromPostsAdminFeed(String postId) async {
    try {
      final response = await _dio.get(
        '/posts/admin/all',
        queryParameters: {
          'page': 1,
          'limit': 50,
          'search': postId,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final page = PostsPageModel.fromJson(data);
      for (final post in page.posts) {
        if (post.id == postId) {
          return _imageUrlFromManagedPost(post);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _imageUrlFromManagedPost(ManagedPostEntity post) {
    final thumb = post.displayThumbnailUrl;
    if (thumb != null && thumb.isNotEmpty && !isLikelyVideoFileUrl(thumb)) {
      return thumb;
    }
    for (final item in post.media) {
      if (item.mediaType.toUpperCase() == 'IMAGE' && item.url.isNotEmpty) {
        return item.url;
      }
    }
    return null;
  }
}
