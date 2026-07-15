import '../../domain/entities/user_interest_entities.dart';
import '../../domain/repositories/user_interests_repository.dart';
import '../datasources/user_interests_remote_data_source.dart';

class UserInterestsRepositoryImpl implements UserInterestsRepository {
  UserInterestsRepositoryImpl(this._remote);

  final UserInterestsRemoteDataSource _remote;

  @override
  Future<UserInterestsResponseEntity> getUserInterests(String userId) {
    return _remote.getUserInterests(userId);
  }
}
