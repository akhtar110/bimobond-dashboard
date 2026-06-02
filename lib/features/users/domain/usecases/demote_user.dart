import '../repositories/users_repository.dart';

class DemoteUser {
  const DemoteUser(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId) {
    return repository.demoteFromAdmin(userId);
  }
}