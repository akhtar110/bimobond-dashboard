import '../repositories/user_activity_repository.dart';

class DeleteRepostAdmin {
  const DeleteRepostAdmin(this._repository);

  final UserActivityRepository _repository;

  Future<void> call(String repostId) => _repository.deleteRepostAsAdmin(repostId);
}
