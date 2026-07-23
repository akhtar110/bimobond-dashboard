import '../repositories/users_repository.dart';

class SuspendUserUseCase {
  const SuspendUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.suspendUser(userId);
}

class UnsuspendUserUseCase {
  const UnsuspendUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.unsuspendUser(userId);
}

class AdminBanUserUseCase {
  const AdminBanUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.banUser(userId);
}

class AdminUnbanUserUseCase {
  const AdminUnbanUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.unbanUser(userId);
}

class VerifyUserUseCase {
  const VerifyUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.verifyUser(userId);
}

class UnverifyUserUseCase {
  const UnverifyUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.unverifyUser(userId);
}

class ActivateUserUseCase {
  const ActivateUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.activateUser(userId);
}

class DeactivateUserUseCase {
  const DeactivateUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.deactivateUser(userId);
}

class DeleteUserUseCase {
  const DeleteUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId) => _repository.deleteUser(userId);
}

class SetUserPostingAllowedUseCase {
  const SetUserPostingAllowedUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId, {required bool allowed}) {
    return _repository.setUserCanPost(userId, canPost: allowed);
  }
}

class SetUserChatMutedUseCase {
  const SetUserChatMutedUseCase(this._repository);

  final UsersRepository _repository;

  Future<void> call(String userId, {required bool muted}) {
    return _repository.setUserAllowDirectMsgs(userId, allow: !muted);
  }
}
