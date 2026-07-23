import 'package:equatable/equatable.dart';

import '../../domain/repositories/rbac_repository.dart';
import 'rbac_state.dart';

sealed class RbacEvent extends Equatable {
  const RbacEvent();
  @override
  List<Object?> get props => const [];
}

class LoadCurrentPermissions extends RbacEvent {
  const LoadCurrentPermissions({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

class LoadRoles extends RbacEvent {
  const LoadRoles({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

class RefreshRoles extends RbacEvent {
  const RefreshRoles();
}

class SearchRoles extends RbacEvent {
  const SearchRoles(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class FilterRoles extends RbacEvent {
  const FilterRoles({this.typeFilter, this.statusFilter});

  final RoleTypeFilter? typeFilter;
  final RoleStatusFilter? statusFilter;

  @override
  List<Object?> get props => [typeFilter, statusFilter];
}

class ChangeRolesPage extends RbacEvent {
  const ChangeRolesPage(this.page);
  final int page;
  @override
  List<Object?> get props => [page];
}

class LoadPermissions extends RbacEvent {
  const LoadPermissions();
}

class LoadRoleDetails extends RbacEvent {
  const LoadRoleDetails(this.roleId);
  final String roleId;
  @override
  List<Object?> get props => [roleId];
}

class CreateRole extends RbacEvent {
  const CreateRole(this.draft);
  final RoleDraft draft;
  @override
  List<Object?> get props => [draft];
}

class UpdateRole extends RbacEvent {
  const UpdateRole(this.roleId, this.draft);
  final String roleId;
  final RoleDraft draft;
  @override
  List<Object?> get props => [roleId, draft];
}

class DeleteRole extends RbacEvent {
  const DeleteRole(this.roleId);
  final String roleId;
  @override
  List<Object?> get props => [roleId];
}

class LoadUserRoles extends RbacEvent {
  const LoadUserRoles(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class AssignUserRoles extends RbacEvent {
  const AssignUserRoles(this.userId, this.roleIds);
  final String userId;
  final List<String> roleIds;
  @override
  List<Object?> get props => [userId, roleIds];
}

class LoadRoleUsers extends RbacEvent {
  const LoadRoleUsers(this.roleId);
  final String roleId;
  @override
  List<Object?> get props => [roleId];
}

class ClearRoleUsers extends RbacEvent {
  const ClearRoleUsers();
}

class ClearRbacFeedback extends RbacEvent {
  const ClearRbacFeedback();
}
