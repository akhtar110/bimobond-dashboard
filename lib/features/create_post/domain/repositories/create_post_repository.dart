import '../entities/create_post_entity.dart';

abstract class CreatePostRepository {
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files);

  Future<Map<String, dynamic>> createPost(CreatePostEntity entity);
}
