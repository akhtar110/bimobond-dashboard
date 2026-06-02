import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
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

    final user = _mapUser(result);
    await saveSession(user);
    return user;
  }

  @override
  Future<DashboardUserEntity> loginWithGoogle() async {
    final result = await remote.loginWithGoogle();
    final user = _mapUser(result);
    await saveSession(user);
    return user;
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

  DashboardUserEntity _mapUser(Map<String, dynamic> result) {
    return DashboardUserEntity(
      id: result['id'],
      email: result['email'] ?? '',
      username: result['username'] ?? '',
      isVerified: result['isVerified'] ?? false,
      isNewUser: result['isNewUser'] ?? false,
      isProfileIncomplete: result['isProfileIncomplete'] ?? false,
    );
  }
}