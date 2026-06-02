import '../entities/post_filters.dart';
import '../repositories/post_repository.dart';

class GetAllPosts {
  const GetAllPosts(this.repository);

  final PostListRepository repository;

  Future<PostsPage> call({
    required int page,
    required int limit,
    required PostFilters filters,
  }) {
    return repository.getAllPosts(
      page: page,
      limit: limit,
      filters: filters,
    );
  }
}
