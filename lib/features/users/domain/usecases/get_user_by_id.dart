import '../entities/user_detail_entity.dart';
import '../repositories/users_repository.dart';

class GetUserById {
  final UsersRepository repository;

  GetUserById(this.repository);

  Future<UserDetailEntity> call(String userId) {
    return repository.getUserById(userId);
  }
}
