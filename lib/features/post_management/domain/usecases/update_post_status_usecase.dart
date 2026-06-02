import '../entities/managed_post_entity.dart';
import '../repositories/post_management_repository.dart';

class UpdatePostStatus {
  const UpdatePostStatus(this.repository);

  final PostManagementRepository repository;

  Future<ManagedPostEntity> call(String postId, String status) =>
      repository.updatePostStatus(postId, status);
}
