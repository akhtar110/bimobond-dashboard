import '../entities/admin_bulk_users_result_entity.dart';
import '../repositories/users_repository.dart';

class BulkSuspendUsers {
  const BulkSuspendUsers(this.repository);

  final UsersRepository repository;

  Future<AdminBulkUsersResultEntity> call(
    List<String> userIds, {
    String reason = 'Bulk admin action',
    DateTime? until,
  }) {
    return repository.suspendUsers(
      userIds,
      reason: reason,
      until: until ?? DateTime.now().add(const Duration(days: 3650)),
    );
  }
}
