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
  RbacRepositoryImpl(this._remoteDataSource, {GetUsers? getUsers})
      : _getUsers = getUsers;

  final RbacRemoteDataSource _remoteDataSource;
  final GetUsers? _getUsers;

  /// Shared across a single enrich / fallback pass so we don't re-page users
  /// once per role.
  List<UserEntity>? _usersCache;
  Future<List<UserEntity>>? _usersCacheFuture;

  @override
  Future<UserAuthContextEntity> getCurrentPermissions() =>
      _remoteDataSource.getCurrentPermissions();

  @override
  Future<List<PermissionEntity>> getPermissions() =>
      _remoteDataSource.getPermissions();

  @override
  Future<List<RoleEntity>> getRoles() async {
    final roles = await _remoteDataSource.getRoles();
    return _enrichRolesWithLiveUserCounts(roles);
  }

  @override
  Future<RoleEntity> getRoleDetails(String roleId) async {
    final role = await _remoteDataSource.getRoleDetails(roleId);
    try {
      final users = await _usersForRole(role);
      return role.copyWith(userCount: users.length);
    } catch (_) {
      return role;
    }
  }

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
    final role = await _resolveRole(roleId);
    if (role == null) {
      // Still try the dedicated endpoint when role metadata is unavailable.
      try {
        return await _remoteDataSource.getRoleUsers(roleId);
      } catch (_) {
        return const [];
      }
    }
    return _usersForRole(role);
  }

  /// Make the Users column match what "View users" returns.
  Future<List<RoleEntity>> _enrichRolesWithLiveUserCounts(
    List<RoleEntity> roles,
  ) async {
    if (roles.isEmpty) return roles;

    await _ensureUsersCache();

    final enriched = await Future.wait(
      roles.map((role) async {
        try {
          final users = await _usersForRole(role);
          if (users.isEmpty) {
            // Keep backend count when live resolution failed (e.g. transient).
            return role;
          }
          if (users.length == role.userCount) return role;
          return role.copyWith(userCount: users.length);
        } catch (_) {
          return role;
        }
      }),
    );

    _clearUsersCache();
    return enriched;
  }

  /// Single source of truth for both the Users column and the holders popup.
  Future<List<RoleUserEntity>> _usersForRole(RoleEntity role) async {
    final kind = _kindForSlug(role.slug);

    List<RoleUserEntity>? fromApi;
    try {
      fromApi = await _remoteDataSource.getRoleUsers(role.id);
    } on RbacApiException catch (error) {
      if (!_shouldFallbackRoleUsers(error)) rethrow;
    } catch (_) {
      fromApi = null;
    }

    if (kind == SystemRoleKind.superAdmin) {
      if (fromApi != null && fromApi.isNotEmpty) return fromApi;
      // Dedicated holders route is often empty/missing for super-admin.
      // Resolve via `/rbac/users/:id/roles` on admin candidates only — never
      // treat every legacy admin as a super-admin.
      final assigned = await _usersWithRbacRole(role);
      if (assigned.isNotEmpty) return assigned;
      return fromApi ?? const [];
    }

    if (kind != null) {
      final fromLegacy = await _legacyUsersForKind(kind);
      if (fromApi == null) return fromLegacy;
      // `/rbac/roles/:id/users` often under-reports members (0) while the
      // users directory still has many `USER` accounts — prefer the fuller list.
      if (fromLegacy.length > fromApi.length) return fromLegacy;
      return fromApi;
    }

    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    // Custom roles: fall back to per-user RBAC assignment checks when the
    // holders route is empty but the role reports holders.
    if (role.userCount > 0) {
      final assigned = await _usersWithRbacRole(role);
      if (assigned.isNotEmpty) return assigned;
    }
    return fromApi ?? const [];
  }

  /// Finds users who actually have [role] assigned in RBAC (by id or slug).
  Future<List<RoleUserEntity>> _usersWithRbacRole(RoleEntity role) async {
    final users = await _ensureUsersCache();
    if (users.isEmpty) return const [];

    final kind = _kindForSlug(role.slug);
    // Super-admin holders are almost always also legacy admins — scan those
    // first to avoid N role lookups across the whole user directory.
    var candidates = users
        .where((user) => user.roles.contains(UserRole.admin))
        .toList(growable: false);
    if (candidates.isEmpty || kind != SystemRoleKind.superAdmin) {
      // For custom roles (or when no admins exist), scan a bounded set.
      candidates = users.take(200).toList(growable: false);
    }

    final matches = <RoleUserEntity>[];
    await Future.wait(
      candidates.map((user) async {
        try {
          final ctx = await _remoteDataSource.getUserRoles(user.id);
          final assigned = ctx.roles.any((r) => r.id == role.id) ||
              ctx.roleSlugs.any(
                (slug) =>
                    slug == role.slug ||
                    slug.toLowerCase() == role.slug.toLowerCase(),
              ) ||
              ctx.roles.any(
                (r) =>
                    r.slug == role.slug ||
                    r.slug.toLowerCase() == role.slug.toLowerCase(),
              );
          if (!assigned) return;
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
        } catch (_) {
          // Ignore per-user failures; other candidates may still resolve.
        }
      }),
    );
    return matches;
  }

  Future<RoleEntity?> _resolveRole(String roleId) async {
    try {
      return await _remoteDataSource.getRoleDetails(roleId);
    } catch (_) {
      try {
        final roles = await _remoteDataSource.getRoles();
        for (final item in roles) {
          if (item.id == roleId) return item;
        }
      } catch (_) {}
      return null;
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

  Future<List<RoleUserEntity>> _legacyUsersForKind(SystemRoleKind kind) async {
    if (kind == SystemRoleKind.superAdmin) return const [];

    final users = await _ensureUsersCache();
    if (users.isEmpty) return const [];

    return users
        .where((user) => _userMatchesKind(user, kind))
        .map(
          (user) => RoleUserModel(
            id: user.id,
            username: user.username,
            fullName: user.fullName,
            email: user.email,
            avatarUrl: user.avatarUrl,
            isBanned: user.isBanned,
            isVerified: user.isVerified,
          ),
        )
        .toList(growable: false);
  }

  Future<List<UserEntity>> _ensureUsersCache() async {
    if (_usersCache != null) return _usersCache!;
    final pending = _usersCacheFuture;
    if (pending != null) return pending;

    final future = _fetchUsersPages();
    _usersCacheFuture = future;
    try {
      final users = await future;
      _usersCache = users;
      return users;
    } finally {
      _usersCacheFuture = null;
    }
  }

  void _clearUsersCache() {
    _usersCache = null;
    _usersCacheFuture = null;
  }

  Future<List<UserEntity>> _fetchUsersPages() async {
    final getUsers = _getUsers;
    if (getUsers == null) return const [];

    try {
      final all = <UserEntity>[];
      var page = 1;
      const limit = 100;
      var lastPage = 1;
      // Cap pages to keep role-list loads responsive on large directories.
      while (page <= lastPage && page <= 20) {
        final result = await getUsers(page: page, limit: limit);
        lastPage = result.lastPage;
        all.addAll(result.users);
        page++;
      }
      return all;
    } catch (_) {
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
    final roles = user.roles;
    return switch (kind) {
      SystemRoleKind.admin => roles.contains(UserRole.admin),
      SystemRoleKind.superAdmin => false,
      SystemRoleKind.moderator => roles.contains(UserRole.moderator),
      SystemRoleKind.member =>
        (roles.contains(UserRole.user) || roles.isEmpty) &&
            !roles.contains(UserRole.admin) &&
            !roles.contains(UserRole.moderator),
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
