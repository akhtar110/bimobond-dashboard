import 'package:dio/dio.dart';

import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/usecases/get_managed_post_by_id.dart';
import '../../../posts/data/models/post_model.dart';
import '../../domain/entities/auction_entity.dart';

/// Same preview URL rule as [PostCard] (`displayThumbnailUrl ?? videoUrl`).
String? postCardPreviewUrl(ManagedPostEntity post) =>
    post.displayThumbnailUrl ?? post.videoUrl;

/// Resolves auction card images from the linked post — same source as Posts page.
class AuctionImageLookup {
  AuctionImageLookup(this._getPostById, this._dio);

  final GetManagedPostById _getPostById;
  final Dio _dio;

  final _cache = <String, String?>{};
  final _inFlight = <String, Future<String?>>{};

  Future<String?> previewUrlFor(AuctionEntity auction) async {
    final postId = auction.postId?.trim();
    if (postId != null && postId.isNotEmpty) {
      return _previewForPostId(postId);
    }
    return auction.displayImageUrl;
  }

  Future<String?> _previewForPostId(String postId) async {
    if (_cache.containsKey(postId)) return _cache[postId];

    _inFlight[postId] ??= _resolveFromPosts(postId);
    try {
      final url = await _inFlight[postId]!;
      _cache[postId] = url;
      return url;
    } finally {
      _inFlight.remove(postId);
    }
  }

  Future<String?> _resolveFromPosts(String postId) async {
    final fromDetail = await _fromPostAdminDetail(postId);
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;

    return _fromPostsAdminList(postId);
  }

  Future<String?> _fromPostAdminDetail(String postId) async {
    try {
      final post = await _getPostById(postId);
      return postCardPreviewUrl(post);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromPostsAdminList(String postId) async {
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
          return postCardPreviewUrl(post);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
