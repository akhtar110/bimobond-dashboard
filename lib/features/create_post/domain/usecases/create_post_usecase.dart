import '../entities/create_post_entity.dart';
import '../repositories/create_post_repository.dart';

class CreatePost {
  const CreatePost(this.repository);

  final CreatePostRepository repository;

  Future<Map<String, dynamic>> call(CreatePostEntity entity) {
    return repository.createPost(entity);
  }
}
