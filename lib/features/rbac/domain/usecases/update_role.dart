import '../entities/role_entity.dart';
import '../repositories/rbac_repository.dart';

class UpdateRole {
  const UpdateRole(this._repository);
  final RbacRepository _repository;
  Future<RoleEntity> call(String roleId, RoleDraft draft) =>
      _repository.updateRole(roleId, draft);
}
