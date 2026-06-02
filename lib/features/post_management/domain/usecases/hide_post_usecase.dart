import '../entities/managed_post_entity.dart';
import '../repositories/post_management_repository.dart';

class HidePost {
  const HidePost(this.repository);

  final PostManagementRepository repository;

  Future<ManagedPostEntity> call(String postId) =>
      repository.hidePost(postId);
}
