import '../repositories/post_management_repository.dart';

class DeleteManagedPost {
  const DeleteManagedPost(this.repository);

  final PostManagementRepository repository;

  Future<void> call(String postId) => repository.deleteManagedPost(postId);
}
