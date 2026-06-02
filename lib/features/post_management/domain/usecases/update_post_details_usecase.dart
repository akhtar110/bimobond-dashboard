import '../entities/managed_post_entity.dart';
import '../repositories/post_management_repository.dart';

class UpdatePostDetails {
  const UpdatePostDetails(this.repository);

  final PostManagementRepository repository;

  Future<ManagedPostEntity> call(
    String postId, {
    String? description,
    String? category,
  }) {
    return repository.updatePostDetails(
      postId,
      description: description,
      category: category,
    );
  }
}
