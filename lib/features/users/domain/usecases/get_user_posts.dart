import '../entities/user_post_entity.dart';
import '../repositories/users_repository.dart';

class GetUserPosts {
  final UsersRepository repository;

  GetUserPosts(this.repository);

  Future<UserPostsResponseEntity> call(String userId, {int page = 1, int limit = 20}) {
    return repository.getUserPosts(userId, page: page, limit: limit);
  }
}
