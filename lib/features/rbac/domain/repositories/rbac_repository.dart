import 'package:equatable/equatable.dart';

import '../entities/permission_entity.dart';
import '../entities/role_entity.dart';
import '../entities/role_user_entity.dart';
import '../entities/user_auth_context_entity.dart';

/// Payload for creating or updating a role. Create requires [slug] and
/// [name]; PATCH omits [description] and [isActive] when they are null.
class RoleDraft extends Equatable {
  const RoleDraft({
    required this.slug,
    required this.name,
    required this.permissionIds,
    this.description,
    this.isActive,
  });

  final String slug;
  final String name;
  final List<String> permissionIds;
  final String? description;
  final bool? isActive;

  @override
  List<Object?> get props => [slug, name, permissionIds, description, isActive];
}

abstract class RbacRepository {
  Future<UserAuthContextEntity> getCurrentPermissions();
  Future<List<PermissionEntity>> getPermissions();
  Future<List<RoleEntity>> getRoles();
  Future<RoleEntity> getRoleDetails(String roleId);
  Future<RoleEntity> createRole(RoleDraft draft);
  Future<RoleEntity> updateRole(String roleId, RoleDraft draft);
  Future<void> deleteRole(String roleId);
  Future<UserAuthContextEntity> getUserRoles(String userId);
  Future<UserAuthContextEntity> assignUserRoles(
    String userId,
    List<String> roleIds,
  );
  Future<List<RoleUserEntity>> getRoleUsers(String roleId);
}
