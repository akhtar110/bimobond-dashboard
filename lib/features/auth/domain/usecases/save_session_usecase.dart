import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SaveSessionUseCase {
  final AuthRepository repository;

  const SaveSessionUseCase(this.repository);

  Future<void> call(DashboardUserEntity user) => repository.saveSession(user);
}
