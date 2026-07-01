import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<DashboardUserEntity> login({
    required String email,
    required String password,
  });

  Future<DashboardUserEntity> loginWithGoogle();

  Future<void> saveSession(DashboardUserEntity user);
  Future<DashboardUserEntity?> getSession();
  Future<void> clearSession();
  Future<void> logout();
}