import '../repositories/users_repository.dart';

class BanUser {
  const BanUser(this.repository);

  final UsersRepository repository;

  Future<void> call({
    required String userId,
    required String reason,
    required DateTime until,
  }) {
    return repository.blockUser(
      userId: userId,
      reason: reason,
      until: until,
    );
  }
}