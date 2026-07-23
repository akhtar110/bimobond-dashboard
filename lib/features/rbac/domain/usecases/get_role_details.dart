import '../entities/role_entity.dart';
import '../repositories/rbac_repository.dart';

class GetRoleDetails {
  const GetRoleDetails(this._repository);
  final RbacRepository _repository;
  Future<RoleEntity> call(String roleId) => _repository.getRoleDetails(roleId);
}
