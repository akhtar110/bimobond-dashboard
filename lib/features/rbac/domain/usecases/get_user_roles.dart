import '../entities/user_auth_context_entity.dart';
import '../repositories/rbac_repository.dart';

class GetUserRoles {
  const GetUserRoles(this._repository);
  final RbacRepository _repository;
  Future<UserAuthContextEntity> call(String userId) =>
      _repository.getUserRoles(userId);
}
