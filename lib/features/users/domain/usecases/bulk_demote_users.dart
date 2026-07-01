import '../entities/admin_bulk_users_result_entity.dart';
import '../repositories/users_repository.dart';

class BulkDemoteUsers {
  const BulkDemoteUsers(this.repository);

  final UsersRepository repository;

  Future<AdminBulkUsersResultEntity> call(List<String> userIds) {
    return repository.demoteUsers(userIds);
  }
}
