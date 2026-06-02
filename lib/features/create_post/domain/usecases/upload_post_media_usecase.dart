import '../entities/create_post_entity.dart';
import '../repositories/create_post_repository.dart';

class UploadPostMedia {
  const UploadPostMedia(this.repository);

  final CreatePostRepository repository;

  Future<List<String>> call(List<LocalMediaFile> files) {
    return repository.uploadMediaFiles(files);
  }
}
