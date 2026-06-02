import '../repositories/users_repository.dart';

class PromoteUser {
  const PromoteUser(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId) {
    return repository.promoteToAdmin(userId);
  }
}