import 'package:dio/dio.dart';

import '../models/assign_roles_request_model.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';
import '../models/role_user_model.dart';
import '../models/user_auth_context_model.dart';
import 'rbac_remote_datasource.dart';

class RbacRemoteDataSourceImpl implements RbacRemoteDataSource {
  const RbacRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserAuthContextModel> getCurrentPermissions() => _request(
    () => _dio.get('/rbac/me'),
    (data) => UserAuthContextModel.fromJson(_object(data)),
  );

  @override
  Future<List<PermissionModel>> getPermissions() => _request(
    () => _dio.get('/rbac/permissions'),
    (data) => _items(data, const ['permissions'])
        .map((item) => PermissionModel.fromJson(_object(item)))
        .toList(growable: false),
  );

  @override
  Future<List<RoleModel>> getRoles() => _request(
    () => _dio.get('/rbac/roles'),
    (data) => _items(data, const [
      'roles',
    ]).map((item) => RoleModel.fromJson(_object(item))).toList(growable: false),
  );

  @override
  Future<RoleModel> getRoleDetails(String roleId) => _request(
    () => _dio.get('/rbac/roles/$roleId'),
    (data) => RoleModel.fromJson(_object(data)),
  );

  @override
  Future<RoleModel> createRole(SaveRoleRequestModel request) => _request(
    () => _dio.post('/rbac/roles', data: request.toCreateJson()),
    (data) => RoleModel.fromJson(_object(data)),
  );

  @override
  Future<RoleModel> updateRole(String roleId, SaveRoleRequestModel request) =>
      _request(
        () => _dio.patch('/rbac/roles/$roleId', data: request.toPatchJson()),
        (data) => RoleModel.fromJson(_object(data)),
      );

  @override
  Future<void> deleteRole(String roleId) =>
      _request(() => _dio.delete('/rbac/roles/$roleId'), (_) {});

  @override
  Future<UserAuthContextModel> getUserRoles(String userId) => _request(
    () => _dio.get('/rbac/users/$userId/roles'),
    (data) => UserAuthContextModel.fromJson(_object(data)),
  );

  @override
  Future<UserAuthContextModel> assignUserRoles(
    String userId,
    AssignRolesRequestModel request,
  ) async {
    final data = await _request(
      () => _dio.put('/rbac/users/$userId/roles', data: request.toJson()),
      (data) => data,
    );
    try {
      return UserAuthContextModel.fromJson(_object(data));
    } on FormatException {
      // Empty PUT responses: re-read the authoritative state.
      return getUserRoles(userId);
    }
  }

  @override
  Future<List<RoleUserModel>> getRoleUsers(String roleId) => _request(
        () => _dio.get('/rbac/roles/$roleId/users'),
        (data) {
          try {
            return _items(data, const ['users', 'members', 'roleUsers'])
                .map(_roleUserFromDynamic)
                .where((u) => u.id.isNotEmpty)
                .toList(growable: false);
          } on FormatException {
            // Empty / unexpected payloads → treat as no members.
            return const <RoleUserModel>[];
          }
        },
      );

  RoleUserModel _roleUserFromDynamic(dynamic item) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final nested = map['user'];
      if (nested is Map) {
        return RoleUserModel.fromJson(Map<String, dynamic>.from(nested));
      }
      return RoleUserModel.fromJson(map);
    }
    throw const FormatException('Expected a role user object.');
  }

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await call();
      return parse(_unwrap(response.data));
    } on DioException catch (error) {
      throw RbacApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    } on FormatException catch (error) {
      throw RbacApiException(
        'The RBAC service returned invalid data: ${error.message}',
      );
    }
  }
}

class RbacApiException implements Exception {
  const RbacApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

dynamic _unwrap(dynamic data) {
  var current = data;
  for (var index = 0; index < 3; index++) {
    if (current is! Map) break;
    final map = Map<String, dynamic>.from(current);
    final nested = map['data'] ?? map['result'] ?? map['payload'];
    if (nested == null) break;
    current = nested;
  }
  return current;
}

Map<String, dynamic> _object(dynamic data) {
  final value = _unwrap(data);
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a JSON object.');
}

List<dynamic> _items(dynamic data, List<String> preferredKeys) {
  final value = _unwrap(data);
  if (value is List) return value;
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in [...preferredKeys, 'items', 'data', 'results']) {
      if (map[key] is List) return map[key] as List<dynamic>;
    }
  }
  throw const FormatException('Expected a JSON list.');
}

String _messageFor(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final raw = data['message'] ?? data['error'] ?? data['detail'];
    if (raw is List && raw.isNotEmpty) return raw.join(', ');
    if (raw != null && raw.toString().trim().isNotEmpty) return raw.toString();
  }
  switch (error.response?.statusCode) {
    case 400:
      return 'The RBAC request is invalid. Check the submitted values.';
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'The requested role, user, or permission was not found.';
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Unable to reach the RBAC service. Check your connection and retry.';
  }
  return error.message ?? 'The RBAC request failed.';
}
