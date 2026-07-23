import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../domain/entities/permission_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/role_user_entity.dart';
import '../../domain/entities/user_auth_context_entity.dart';

enum RbacStatus { initial, loading, ready, failure }

enum RoleTypeFilter { all, system, custom }

enum RoleStatusFilter { all, active, inactive }

/// Semantic outcome keys; pages localize them via `tOr`.
enum RbacFeedback { roleCreated, roleUpdated, roleDeleted, userRolesUpdated }

class RbacState extends Equatable {
  const RbacState({
    this.status = RbacStatus.initial,
    this.authContext,
    this.roles = const [],
    this.permissions = const [],
    this.selectedRole,
    this.userRoleContext,
    this.activeUserId,
    this.roleUsers = const [],
    this.roleUsersRoleId,
    this.isLoadingRoleUsers = false,
    this.query = '',
    this.typeFilter = RoleTypeFilter.all,
    this.statusFilter = RoleStatusFilter.all,
    this.currentPage = 1,
    this.isSubmitting = false,
    this.feedback,
    this.errorMessage,
  });

  static const pageSize = 20;

  final RbacStatus status;
  final UserAuthContextEntity? authContext;
  final List<RoleEntity> roles;
  final List<PermissionEntity> permissions;
  final RoleEntity? selectedRole;
  final UserAuthContextEntity? userRoleContext;
  final String? activeUserId;
  final List<RoleUserEntity> roleUsers;
  final String? roleUsersRoleId;
  final bool isLoadingRoleUsers;
  final String query;
  final RoleTypeFilter typeFilter;
  final RoleStatusFilter statusFilter;
  final int currentPage;
  final bool isSubmitting;
  final RbacFeedback? feedback;
  final String? errorMessage;

  List<RoleEntity> get filteredRoles {
    final normalized = query.trim().toLowerCase();
    return roles
        .where((role) {
          final matchesType = switch (typeFilter) {
            RoleTypeFilter.all => true,
            RoleTypeFilter.system => role.isSystem,
            RoleTypeFilter.custom => !role.isSystem,
          };
          final matchesStatus = switch (statusFilter) {
            RoleStatusFilter.all => true,
            RoleStatusFilter.active => role.isActive,
            RoleStatusFilter.inactive => !role.isActive,
          };
          final matchesQuery =
              normalized.isEmpty ||
              role.name.toLowerCase().contains(normalized) ||
              role.slug.toLowerCase().contains(normalized) ||
              (role.description ?? '').toLowerCase().contains(normalized) ||
              role.permissions.any(
                (permission) =>
                    permission.label.toLowerCase().contains(normalized) ||
                    permission.key.toLowerCase().contains(normalized),
              );
          return matchesType && matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }

  int get total => filteredRoles.length;
  int get lastPage => math.max(1, (total / pageSize).ceil());

  List<RoleEntity> get pagedRoles {
    final page = currentPage.clamp(1, lastPage);
    final start = (page - 1) * pageSize;
    return filteredRoles.skip(start).take(pageSize).toList(growable: false);
  }

  RbacState copyWith({
    RbacStatus? status,
    UserAuthContextEntity? authContext,
    List<RoleEntity>? roles,
    List<PermissionEntity>? permissions,
    RoleEntity? selectedRole,
    UserAuthContextEntity? userRoleContext,
    String? activeUserId,
    List<RoleUserEntity>? roleUsers,
    String? roleUsersRoleId,
    bool? isLoadingRoleUsers,
    String? query,
    RoleTypeFilter? typeFilter,
    RoleStatusFilter? statusFilter,
    int? currentPage,
    bool? isSubmitting,
    RbacFeedback? feedback,
    String? errorMessage,
    bool clearSelectedRole = false,
    bool clearActiveUser = false,
    bool clearRoleUsers = false,
    bool clearFeedback = false,
  }) {
    return RbacState(
      status: status ?? this.status,
      authContext: authContext ?? this.authContext,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      selectedRole: clearSelectedRole
          ? null
          : (selectedRole ?? this.selectedRole),
      userRoleContext: userRoleContext ?? this.userRoleContext,
      activeUserId: clearActiveUser
          ? null
          : (activeUserId ?? this.activeUserId),
      roleUsers: clearRoleUsers ? const [] : (roleUsers ?? this.roleUsers),
      roleUsersRoleId: clearRoleUsers
          ? null
          : (roleUsersRoleId ?? this.roleUsersRoleId),
      isLoadingRoleUsers: isLoadingRoleUsers ?? this.isLoadingRoleUsers,
      query: query ?? this.query,
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      errorMessage: clearFeedback ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    authContext,
    roles,
    permissions,
    selectedRole,
    userRoleContext,
    activeUserId,
    roleUsers,
    roleUsersRoleId,
    isLoadingRoleUsers,
    query,
    typeFilter,
    statusFilter,
    currentPage,
    isSubmitting,
    feedback,
    errorMessage,
  ];
}
