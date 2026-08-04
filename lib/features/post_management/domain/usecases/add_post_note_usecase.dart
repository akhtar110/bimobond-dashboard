import '../repositories/post_management_repository.dart';

class AddPostNote {
  const AddPostNote(this.repository);

  final PostManagementRepository repository;

  Future<void> call(String postId, String note) =>
      repository.addPostNote(postId, note);
}
