import '../../../post_management/data/models/managed_post_model.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';

/// Pagination envelope returned by GET /posts/admin/all.
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
    // Support various API response shapes:
    //   { posts: [...], meta: { page, lastPage, total } }
    //   { data: [...],  meta: { ... } }
    final rawList =
        (json['posts'] ?? json['data'] ?? json['videos']) as List?;

    final posts = (rawList ?? [])
        .map((e) => ManagedPostModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;
    final lastPage = (meta['lastPage'] as num?)?.toInt() ?? 1;
    final total = (meta['total'] as num?)?.toInt() ?? posts.length;

    return PostsPageModel(
      posts: posts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}
