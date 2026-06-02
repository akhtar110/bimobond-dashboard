import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository repository;

  const LoginWithGoogleUseCase(this.repository);

  Future<DashboardUserEntity> call() {
    return repository.loginWithGoogle();
  }
}