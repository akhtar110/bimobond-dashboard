import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../entities/post_filters.dart';

abstract class PostListRepository {
  Future<PostsPage> getAllPosts({
    required int page,
    required int limit,
    required PostFilters filters,
  });
}

class PostsPage {
  const PostsPage({
    required this.posts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ManagedPostEntity> posts;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasReachedMax => currentPage >= lastPage;
}
