import '../repositories/users_repository.dart';

class VerifyUser {
  const VerifyUser(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId) => repository.verifyUser(userId);
}
