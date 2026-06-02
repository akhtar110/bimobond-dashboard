import '../entities/user_entity.dart';
import '../repositories/users_repository.dart';

class UpdateUserRoles {
  const UpdateUserRoles(this.repository);

  final UsersRepository repository;

  Future<void> call({
    required String userId,
    required List<UserRole> roles,
  }) {
    return repository.updateUserRoles(
      userId: userId,
      roles: roles,
    );
  }
}