import '../entities/permission_entity.dart';
import '../repositories/rbac_repository.dart';

class GetPermissions {
  const GetPermissions(this._repository);
  final RbacRepository _repository;
  Future<List<PermissionEntity>> call() => _repository.getPermissions();
}
