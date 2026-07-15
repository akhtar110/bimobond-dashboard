import '../entities/user_interest_entities.dart';

abstract class UserInterestsRepository {
  Future<UserInterestsResponseEntity> getUserInterests(String userId);
}
