import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/role_entity.dart';
import '../../domain/usecases/assign_user_roles.dart'
    as assign_user_roles_usecase;
import '../../domain/usecases/create_role.dart' as create_role_usecase;
import '../../domain/usecases/delete_role.dart' as delete_role_usecase;
import '../../domain/usecases/get_current_permissions.dart';
import '../../domain/usecases/get_permissions.dart';
import '../../domain/usecases/get_role_details.dart';
import '../../domain/usecases/get_role_users.dart';
import '../../domain/usecases/get_roles.dart';
import '../../domain/usecases/get_user_roles.dart';
import '../../domain/usecases/update_role.dart' as update_role_usecase;
import 'rbac_event.dart';
import 'rbac_state.dart';

export 'rbac_state.dart';

class RbacBloc extends Bloc<RbacEvent, RbacState> {
  RbacBloc({
    required this.getCurrentPermissions,
    required this.getPermissions,
    required this.getRoles,
    required this.getRoleDetails,
    required this.createRole,
    required this.updateRole,
    required this.deleteRole,
    required this.getUserRoles,
    required this.assignUserRoles,
    required this.getRoleUsers,
  }) : super(const RbacState()) {
    on<LoadCurrentPermissions>(_onLoadCurrentPermissions);
    on<LoadRoles>(_onLoadRoles);
    on<RefreshRoles>(_onRefresh);
    on<SearchRoles>(_onSearch);
    on<FilterRoles>(_onFilter);
    on<ChangeRolesPage>(_onChangePage);
    on<LoadPermissions>(_onLoadPermissions);
    on<LoadRoleDetails>(_onLoadRoleDetails);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<DeleteRole>(_onDeleteRole);
    on<LoadUserRoles>(_onLoadUserRoles);
    on<AssignUserRoles>(_onAssignUserRoles);
    on<LoadRoleUsers>(_onLoadRoleUsers);
    on<ClearRoleUsers>(_onClearRoleUsers);
    on<ClearRbacFeedback>(_onClearFeedback);
  }

  final GetCurrentPermissions getCurrentPermissions;
  final GetPermissions getPermissions;
  final GetRoles getRoles;
  final GetRoleDetails getRoleDetails;
  final create_role_usecase.CreateRole createRole;
  final update_role_usecase.UpdateRole updateRole;
  final delete_role_usecase.DeleteRole deleteRole;
  final GetUserRoles getUserRoles;
  final assign_user_roles_usecase.AssignUserRoles assignUserRoles;
  final GetRoleUsers getRoleUsers;
  DateTime? _lastAuthContextLoad;

  Future<void> _onLoadCurrentPermissions(
    LoadCurrentPermissions event,
    Emitter<RbacState> emit,
  ) async {
    final loadedAt = _lastAuthContextLoad;
    if (!event.force &&
        state.authContext != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(seconds: 60)) {
      return;
    }
    try {
      final context = await getCurrentPermissions();
      _lastAuthContextLoad = DateTime.now();
      emit(state.copyWith(authContext: context));
    } catch (error) {
      emit(_failure(error));
    }
  }

  Future<void> _onLoadRoles(LoadRoles event, Emitter<RbacState> emit) async {
    emit(state.copyWith(status: RbacStatus.loading, clearFeedback: true));
    try {
      final roles = await getRoles();
      emit(
        state.copyWith(
          status: RbacStatus.ready,
          roles: roles,
          currentPage: event.refresh
              ? 1
              : state.currentPage.clamp(1, _lastPageFor(roles)),
        ),
      );
    } catch (error) {
      emit(_failure(error));
    }
  }

  Future<void> _onRefresh(RefreshRoles event, Emitter<RbacState> emit) async {
    emit(state.copyWith(status: RbacStatus.loading, clearFeedback: true));
    try {
      final authContextFuture = getCurrentPermissions();
      final permissionsFuture = getPermissions();
      final rolesFuture = getRoles();
      final authContext = await authContextFuture;
      final permissions = await permissionsFuture;
      final roles = await rolesFuture;
      _lastAuthContextLoad = DateTime.now();
      emit(
        state.copyWith(
          status: RbacStatus.ready,
          authContext: authContext,
          permissions: permissions,
          roles: roles,
          currentPage: 1,
        ),
      );
    } catch (error) {
      emit(_failure(error));
    }
  }

  void _onSearch(SearchRoles event, Emitter<RbacState> emit) {
    emit(state.copyWith(query: event.query, currentPage: 1));
  }

  void _onFilter(FilterRoles event, Emitter<RbacState> emit) {
    emit(
      state.copyWith(
        typeFilter: event.typeFilter,
        statusFilter: event.statusFilter,
        currentPage: 1,
      ),
    );
  }

  void _onChangePage(ChangeRolesPage event, Emitter<RbacState> emit) {
    emit(state.copyWith(currentPage: event.page.clamp(1, state.lastPage)));
  }

  Future<void> _onLoadPermissions(
    LoadPermissions event,
    Emitter<RbacState> emit,
  ) async {
    if (state.permissions.isEmpty) {
      emit(state.copyWith(status: RbacStatus.loading, clearFeedback: true));
    }
    try {
      final permissions = await getPermissions();
      emit(state.copyWith(status: RbacStatus.ready, permissions: permissions));
    } catch (error) {
      emit(_failure(error));
    }
  }

  Future<void> _onLoadRoleDetails(
    LoadRoleDetails event,
    Emitter<RbacState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RbacStatus.loading,
        clearSelectedRole: true,
        clearFeedback: true,
      ),
    );
    try {
      final role = await getRoleDetails(event.roleId);
      emit(state.copyWith(status: RbacStatus.ready, selectedRole: role));
    } catch (error) {
      emit(_failure(error));
    }
  }

  Future<void> _onCreateRole(CreateRole event, Emitter<RbacState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final role = await createRole(event.draft);
      emit(
        state.copyWith(
          status: RbacStatus.ready,
          roles: [...state.roles, role],
          selectedRole: role,
          isSubmitting: false,
          feedback: RbacFeedback.roleCreated,
        ),
      );
    } catch (error) {
      emit(_submissionFailure(error));
    }
  }

  Future<void> _onUpdateRole(UpdateRole event, Emitter<RbacState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final role = await updateRole(event.roleId, event.draft);
      emit(
        state.copyWith(
          status: RbacStatus.ready,
          roles: _replaceRole(state.roles, role),
          selectedRole: role,
          isSubmitting: false,
          feedback: RbacFeedback.roleUpdated,
        ),
      );
    } catch (error) {
      emit(_submissionFailure(error));
    }
  }

  Future<void> _onDeleteRole(DeleteRole event, Emitter<RbacState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await deleteRole(event.roleId);
      emit(
        state.copyWith(
          roles: state.roles.where((role) => role.id != event.roleId).toList(),
          isSubmitting: false,
          clearSelectedRole: state.selectedRole?.id == event.roleId,
          feedback: RbacFeedback.roleDeleted,
          currentPage: 1,
        ),
      );
    } catch (error) {
      emit(_submissionFailure(error));
    }
  }

  Future<void> _onLoadUserRoles(
    LoadUserRoles event,
    Emitter<RbacState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RbacStatus.loading,
        activeUserId: event.userId,
        clearFeedback: true,
      ),
    );
    try {
      final context = await getUserRoles(event.userId);
      emit(
        state.copyWith(
          status: RbacStatus.ready,
          activeUserId: event.userId,
          userRoleContext: context,
        ),
      );
    } catch (error) {
      emit(_failure(error));
    }
  }

  Future<void> _onAssignUserRoles(
    AssignUserRoles event,
    Emitter<RbacState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final context = await assignUserRoles(event.userId, event.roleIds);
      emit(
        state.copyWith(
          activeUserId: event.userId,
          userRoleContext: context,
          isSubmitting: false,
          feedback: RbacFeedback.userRolesUpdated,
        ),
      );
    } catch (error) {
      emit(_submissionFailure(error));
    }
  }

  Future<void> _onLoadRoleUsers(
    LoadRoleUsers event,
    Emitter<RbacState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingRoleUsers: true,
        roleUsersRoleId: event.roleId,
        clearFeedback: true,
      ),
    );
    try {
      final users = await getRoleUsers(event.roleId);
      emit(
        state.copyWith(
          isLoadingRoleUsers: false,
          roleUsers: users,
          roleUsersRoleId: event.roleId,
          clearFeedback: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingRoleUsers: false,
          roleUsers: const [],
          roleUsersRoleId: event.roleId,
          errorMessage: _readable(error),
        ),
      );
    }
  }

  void _onClearRoleUsers(ClearRoleUsers event, Emitter<RbacState> emit) {
    emit(state.copyWith(clearRoleUsers: true, isLoadingRoleUsers: false));
  }

  void _onClearFeedback(ClearRbacFeedback event, Emitter<RbacState> emit) {
    emit(state.copyWith(clearFeedback: true));
  }

  RbacState _failure(Object error) => state.copyWith(
    status: RbacStatus.failure,
    isSubmitting: false,
    errorMessage: _readable(error),
  );

  RbacState _submissionFailure(Object error) =>
      state.copyWith(isSubmitting: false, errorMessage: _readable(error));

  String _readable(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  int _lastPageFor(List<RoleEntity> roles) =>
      (roles.length / RbacState.pageSize).ceil().clamp(1, 1 << 31);

  List<RoleEntity> _replaceRole(
    List<RoleEntity> roles,
    RoleEntity replacement,
  ) {
    final index = roles.indexWhere((role) => role.id == replacement.id);
    if (index < 0) return [...roles, replacement];
    final result = List<RoleEntity>.of(roles);
    result[index] = replacement;
    return result;
  }
}
