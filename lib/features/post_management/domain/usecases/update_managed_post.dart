import '../entities/managed_post_entity.dart';
import '../repositories/post_management_repository.dart';

class UpdateManagedPost {
  const UpdateManagedPost(this.repository);

  final PostManagementRepository repository;

  Future<ManagedPostEntity> call(String postId, ManagedPostUpdateData data) {
    return repository.updateManagedPost(postId, data);
  }
}
