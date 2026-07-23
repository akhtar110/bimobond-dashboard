import '../repositories/rbac_repository.dart';

class DeleteRole {
  const DeleteRole(this._repository);
  final RbacRepository _repository;
  Future<void> call(String roleId) => _repository.deleteRole(roleId);
}
