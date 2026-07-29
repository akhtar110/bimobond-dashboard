import '../entities/user_history_entity.dart';

abstract class UserHistoryRepository {
  Future<UserHistoryPageEntity> getUserHistory({
    required String userId,
    required UserHistoryQuery query,
  });
}
