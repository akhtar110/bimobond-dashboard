import '../entities/user_history_entity.dart';
import '../repositories/user_history_repository.dart';

class GetUserHistoryUseCase {
  GetUserHistoryUseCase(this._repository);

  final UserHistoryRepository _repository;

  Future<UserHistoryPageEntity> call({
    required String userId,
    required UserHistoryQuery query,
  }) {
    return _repository.getUserHistory(userId: userId, query: query);
  }
}
