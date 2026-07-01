import '../entities/admin_bulk_users_result_entity.dart';
import '../repositories/users_repository.dart';

class BulkActivateUsers {
  const BulkActivateUsers(this.repository);

  final UsersRepository repository;

  Future<AdminBulkUsersResultEntity> call(List<String> userIds) {
    return repository.activateUsers(userIds);
  }
}
