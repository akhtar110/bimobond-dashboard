import '../entities/user_entity.dart';
import '../repositories/users_repository.dart';

class GetUsers {
  const GetUsers(this.repository);

  final UsersRepository repository;

  Future<UsersPageEntity> call({
    required int page,
    required int limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
    String? location,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) {
    return repository.getUsers(
      page: page,
      limit: limit,
      search: search,
      isVerified: isVerified,
      isBanned: isBanned,
      location: location,
      role: role,
      createdFrom: createdFrom,
      createdTo: createdTo,
    );
  }
}
