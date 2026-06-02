import '../repositories/users_repository.dart';

class UnbanUser {
  const UnbanUser(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId) {
    return repository.unblockUser(userId);
  }
}