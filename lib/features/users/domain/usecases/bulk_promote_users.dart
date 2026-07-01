import '../entities/admin_bulk_users_result_entity.dart';
import '../repositories/users_repository.dart';

class BulkPromoteUsers {
  const BulkPromoteUsers(this.repository);

  final UsersRepository repository;

  Future<AdminBulkUsersResultEntity> call(List<String> userIds) {
    return repository.promoteUsers(userIds);
  }
}
