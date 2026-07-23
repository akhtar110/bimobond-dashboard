import '../entities/user_auth_context_entity.dart';
import '../repositories/rbac_repository.dart';

class AssignUserRoles {
  const AssignUserRoles(this._repository);
  final RbacRepository _repository;
  Future<UserAuthContextEntity> call(String userId, List<String> roleIds) =>
      _repository.assignUserRoles(userId, roleIds);
}
