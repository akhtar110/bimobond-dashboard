import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_users.dart';
import '../../domain/entities/permission_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/role_user_entity.dart';
import '../../domain/entities/user_auth_context_entity.dart';
import '../../domain/repositories/rbac_repository.dart';
import '../datasources/rbac_remote_datasource.dart';
import '../datasources/rbac_remote_datasource_impl.dart';
import '../models/assign_roles_request_model.dart';
import '../models/role_user_model.dart';

class RbacRepositoryImpl implements RbacRepository {
  const RbacRepositoryImpl(this._remoteDataSource, {GetUsers? getUsers})
      : _getUsers = getUsers;

  final RbacRemoteDataSource _remoteDataSource;
  final GetUsers? _getUsers;

  @override
  Future<UserAuthContextEntity> getCurrentPermissions() =>
      _remoteDataSource.getCurrentPermissions();

  @override
  Future<List<PermissionEntity>> getPermissions() =>
      _remoteDataSource.getPermissions();

  @override
  Future<List<RoleEntity>> getRoles() => _remoteDataSource.getRoles();

  @override
  Future<RoleEntity> getRoleDetails(String roleId) =>
      _remoteDataSource.getRoleDetails(roleId);

  @override
  Future<RoleEntity> createRole(RoleDraft draft) =>
      _remoteDataSource.createRole(_request(draft));

  @override
  Future<RoleEntity> updateRole(String roleId, RoleDraft draft) =>
      _remoteDataSource.updateRole(roleId, _request(draft));

  @override
  Future<void> deleteRole(String roleId) =>
      _remoteDataSource.deleteRole(roleId);

  @override
  Future<UserAuthContextEntity> getUserRoles(String userId) =>
      _remoteDataSource.getUserRoles(userId);

  @override
  Future<UserAuthContextEntity> assignUserRoles(
    String userId,
    List<String> roleIds,
  ) =>
      _remoteDataSource.assignUserRoles(
        userId,
        AssignRolesRequestModel(roleIds),
      );

  @override
  Future<List<RoleUserEntity>> getRoleUsers(String roleId) async {
    try {
      return await _remoteDataSource.getRoleUsers(roleId);
    } on RbacApiException catch (error) {
      // Dedicated role-users route is optional on some backends.
      if (_shouldFallbackRoleUsers(error)) {
        return _fallbackRoleUsers(roleId);
      }
      rethrow;
    } catch (_) {
      return _fallbackRoleUsers(roleId);
    }
  }

  bool _shouldFallbackRoleUsers(RbacApiException error) {
    final code = error.statusCode;
    if (code == null) return true;
    return code == 404 ||
        code == 405 ||
        code == 501 ||
        code == 502 ||
        code == 503;
  }

  Future<List<RoleUserEntity>> _fallbackRoleUsers(String roleId) async {
    final getUsers = _getUsers;
    if (getUsers == null) return const [];

    try {
      RoleEntity? role;
      try {
        role = await _remoteDataSource.getRoleDetails(roleId);
      } catch (_) {
        final roles = await _remoteDataSource.getRoles();
        for (final item in roles) {
          if (item.id == roleId) {
            role = item;
            break;
          }
        }
      }
      if (role == null) return const [];

      final kind = _kindForSlug(role.slug);
      if (kind == null) return const [];

      final matches = <RoleUserEntity>[];
      var page = 1;
      const limit = 100;
      var lastPage = 1;
      while (page <= lastPage && page <= 5) {
        final result = await getUsers(page: page, limit: limit);
        lastPage = result.lastPage;
        for (final user in result.users) {
          if (_userMatchesKind(user, kind)) {
            matches.add(
              RoleUserModel(
                id: user.id,
                username: user.username,
                fullName: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl,
                isBanned: user.isBanned,
                isVerified: user.isVerified,
              ),
            );
          }
        }
        page++;
      }
      return matches;
    } catch (_) {
      // Fallback scan failed (network/CORS/etc.) — surface empty rather than crash UI.
      return const [];
    }
  }

  SystemRoleKind? _kindForSlug(String slug) {
    for (final kind in SystemRoleKind.values) {
      if (kind.matchesSlug(slug)) return kind;
    }
    return null;
  }

  bool _userMatchesKind(UserEntity user, SystemRoleKind kind) {
    return switch (kind) {
      SystemRoleKind.admin => user.roles.contains(UserRole.admin),
      SystemRoleKind.superAdmin => user.roles.contains(UserRole.admin),
      SystemRoleKind.moderator => user.roles.contains(UserRole.moderator),
      SystemRoleKind.member =>
        user.roles.contains(UserRole.user) || user.roles.isEmpty,
    };
  }

  SaveRoleRequestModel _request(RoleDraft draft) => SaveRoleRequestModel(
        slug: draft.slug,
        name: draft.name,
        permissionIds: draft.permissionIds,
        description: draft.description,
        isActive: draft.isActive,
      );
}
