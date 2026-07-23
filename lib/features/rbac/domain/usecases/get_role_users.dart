import '../entities/role_user_entity.dart';
import '../repositories/rbac_repository.dart';

class GetRoleUsers {
  const GetRoleUsers(this._repository);

  final RbacRepository _repository;

  Future<List<RoleUserEntity>> call(String roleId) =>
      _repository.getRoleUsers(roleId);
}
