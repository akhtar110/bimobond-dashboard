import '../repositories/users_repository.dart';

class ResetUserPasswordParams {
  const ResetUserPasswordParams({
    required this.userId,
    required this.newPassword,
  });

  final String userId;
  final String newPassword;
}

class ResetUserPasswordUseCase {
  const ResetUserPasswordUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(ResetUserPasswordParams params) {
    return _repository.resetUserPassword(
      userId: params.userId,
      newPassword: params.newPassword,
    );
  }
}
