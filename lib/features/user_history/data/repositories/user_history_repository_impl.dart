import '../../domain/entities/user_history_entity.dart';
import '../../domain/repositories/user_history_repository.dart';
import '../datasources/user_history_remote_datasource.dart';

class UserHistoryRepositoryImpl implements UserHistoryRepository {
  UserHistoryRepositoryImpl(this._remote);

  final UserHistoryRemoteDataSource _remote;

  @override
  Future<UserHistoryPageEntity> getUserHistory({
    required String userId,
    required UserHistoryQuery query,
  }) {
    return _remote.getUserHistory(userId: userId, query: query);
  }
}
