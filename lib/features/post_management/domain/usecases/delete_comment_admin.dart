import '../repositories/post_management_repository.dart';

class DeleteCommentAdmin {
  const DeleteCommentAdmin(this.repository);

  final PostManagementRepository repository;

  Future<void> call(String commentId) =>
      repository.deleteCommentAsAdmin(commentId);
}
