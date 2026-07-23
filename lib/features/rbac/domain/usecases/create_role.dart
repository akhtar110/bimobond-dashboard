import '../entities/role_entity.dart';
import '../repositories/rbac_repository.dart';

class CreateRole {
  const CreateRole(this._repository);
  final RbacRepository _repository;
  Future<RoleEntity> call(RoleDraft draft) => _repository.createRole(draft);
}
