import '../entities/user_auth_context_entity.dart';
import '../repositories/rbac_repository.dart';

class GetCurrentPermissions {
  const GetCurrentPermissions(this._repository);
  final RbacRepository _repository;
  Future<UserAuthContextEntity> call() => _repository.getCurrentPermissions();
}
