import '../models/assign_roles_request_model.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';
import '../models/role_user_model.dart';
import '../models/user_auth_context_model.dart';

abstract class RbacRemoteDataSource {
  Future<UserAuthContextModel> getCurrentPermissions();
  Future<List<PermissionModel>> getPermissions();
  Future<List<RoleModel>> getRoles();
  Future<RoleModel> getRoleDetails(String roleId);
  Future<RoleModel> createRole(SaveRoleRequestModel request);
  Future<RoleModel> updateRole(String roleId, SaveRoleRequestModel request);
  Future<void> deleteRole(String roleId);
  Future<UserAuthContextModel> getUserRoles(String userId);
  Future<UserAuthContextModel> assignUserRoles(
    String userId,
    AssignRolesRequestModel request,
  );

  /// Users that currently hold [roleId].
  Future<List<RoleUserModel>> getRoleUsers(String roleId);
}
