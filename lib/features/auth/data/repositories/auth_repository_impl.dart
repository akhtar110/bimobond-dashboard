import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/utils/user_roles_parser.dart';
import '../datasource/auth_local_data_source.dart';
import '../datasource/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  AuthRepositoryImpl(this.remote, this.local);

  @override
  Future<DashboardUserEntity> login({
    required String email,
    required String password,
  }) async {
    final result = await remote.login(
      LoginRequestModel(email: email, password: password),
    );

    return _mapUser(result);
  }

  @override
  Future<DashboardUserEntity> loginWithGoogle() async {
    final result = await remote.loginWithGoogle();
    return _mapUser(result);
  }

  @override
  Future<void> saveSession(DashboardUserEntity user) async {
    await local.saveSession(DashboardUserModel(
      id: user.id,
      email: user.email,
      username: user.username,
      isVerified: user.isVerified,
      isNewUser: user.isNewUser,
      isProfileIncomplete: user.isProfileIncomplete,
      roles: user.roles,
    ));
  }

  @override
  Future<DashboardUserEntity?> getSession() async {
    return await local.getSession();
  }

  @override
  Future<void> clearSession() async {
    await local.clearSession();
  }

  @override
  Future<void> logout() async {
    await remote.signOut();
    await local.clearSession();
  }

  DashboardUserEntity _mapUser(Map<String, dynamic> result) {
    final userPayload = result['user'];
    final rolesSource = result['roles'] ??
        (userPayload is Map ? userPayload['roles'] : null);

    return DashboardUserEntity(
      id: (result['id'] ??
              result['_id'] ??
              (userPayload is Map ? userPayload['id'] : null) ??
              (userPayload is Map ? userPayload['_id'] : null) ??
              '')
          .toString(),
      email: result['email'] ?? (userPayload is Map ? userPayload['email'] : null) ?? '',
      username: result['username'] ??
          (userPayload is Map ? userPayload['username'] : null) ??
          '',
      isVerified: result['isVerified'] ??
          (userPayload is Map ? userPayload['isVerified'] : null) ??
          false,
      isNewUser: result['isNewUser'] ??
          (userPayload is Map ? userPayload['isNewUser'] : null) ??
          false,
      isProfileIncomplete: result['isProfileIncomplete'] ??
          (userPayload is Map ? userPayload['isProfileIncomplete'] : null) ??
          false,
      roles: parseUserRoles(rolesSource),
    );
  }
}
