import '../entities/message_permission.dart';
import '../repositories/users_repository.dart';

class SetUserMessagePermission {
  const SetUserMessagePermission(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId, {required MessagePermission permission}) {
    return repository.setUserMessagePermission(userId, permission: permission);
  }
}
