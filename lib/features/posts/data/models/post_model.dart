import '../../../post_management/data/models/managed_post_model.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';

/// Pagination envelope returned by GET /posts/feed (FeedQueryDto).
/// Each item is parsed as a [ManagedPostModel] (which extends [ManagedPostEntity]),
/// so the same entity type flows all the way through to the UI.
class PostsPageModel {
  const PostsPageModel({
    required this.posts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ManagedPostEntity> posts;
  final int currentPage;
  final int lastPage;
  final int total;

  factory PostsPageModel.fromJson(Map<String, dynamic> json) {
    // README response shape for GET /posts/feed:
    //   { "data": [...], "meta": { "total": N, "page": N, "limit": N, "totalPages": N } }
    // The key for the post list is "data"; "posts" is kept as fallback only.
    final rawList =
        (json['data'] ?? json['posts'] ?? json['videos']) as List?;

    final posts = (rawList ?? [])
        .map((e) => ManagedPostModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;

    // README uses "totalPages" (not "lastPage").  Reading "lastPage" would
    // always return null → default to 1 → hasReachedMax always true on page 1,
    // completely breaking pagination.  "lastPage" is kept as a fallback only.
    final lastPage = (meta['totalPages'] as num?)?.toInt() ??
        (meta['lastPage'] as num?)?.toInt() ??
        1;

    final total = (meta['total'] as num?)?.toInt() ?? posts.length;

    return PostsPageModel(
      posts: posts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}
