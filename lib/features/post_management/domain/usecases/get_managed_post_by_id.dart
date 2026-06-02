import '../entities/managed_post_entity.dart';
import '../repositories/post_management_repository.dart';

class GetManagedPostById {
  const GetManagedPostById(this.repository);

  final PostManagementRepository repository;

  Future<ManagedPostEntity> call(String postId) {
    return repository.getManagedPostById(postId);
  }
}
