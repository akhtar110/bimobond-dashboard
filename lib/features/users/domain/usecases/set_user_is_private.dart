import '../repositories/users_repository.dart';
class SetUserIsPrivate {
  const SetUserIsPrivate(this.repository);

  final UsersRepository repository;

  Future<void> call(String userId, {required bool isPrivate}) {
    return repository.setUserIsPrivate(userId, isPrivate: isPrivate);
  }
}
