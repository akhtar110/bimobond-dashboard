import '../entities/user_interest_entities.dart';
import '../repositories/user_interests_repository.dart';

class GetUserInterestsUseCase {
  const GetUserInterestsUseCase(this._repository);

  final UserInterestsRepository _repository;

  Future<UserInterestsResponseEntity> call(String userId) {
    return _repository.getUserInterests(userId);
  }
}
