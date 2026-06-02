import '../../domain/entities/post_filters.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/posts_remote_data_source.dart';

class PostListRepositoryImpl implements PostListRepository {
  const PostListRepositoryImpl(this._dataSource);

  final PostsRemoteDataSource _dataSource;

  @override
  Future<PostsPage> getAllPosts({
    required int page,
    required int limit,
    required PostFilters filters,
  }) async {
    final model = await _dataSource.getAllPosts(
      page: page,
      limit: limit,
      filters: filters,
    );
    return PostsPage(
      posts: model.posts,
      currentPage: model.currentPage,
      lastPage: model.lastPage,
      total: model.total,
    );
  }
}
