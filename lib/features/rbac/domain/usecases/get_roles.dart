import '../entities/role_entity.dart';
import '../repositories/rbac_repository.dart';

class GetRoles {
  const GetRoles(this._repository);
  final RbacRepository _repository;
  Future<List<RoleEntity>> call() => _repository.getRoles();
}
