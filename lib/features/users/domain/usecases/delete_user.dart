import '../repositories/users_repository.dart';

class DeleteUser {
  const DeleteUser(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId) {
    return repository.deleteUser(userId);
  }
}