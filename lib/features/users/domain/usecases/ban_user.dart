import '../repositories/users_repository.dart';

class BanUser {
  const BanUser(this.repository);

  final UsersRepository repository;

  Future<void> call({
    required String userId,
    required String reason,
    DateTime? until,
  }) {
    return repository.blockUser(
      userId: userId,
      reason: reason.trim().isEmpty ? 'Banned by admin' : reason.trim(),
      until: until,
    );
  }
}
