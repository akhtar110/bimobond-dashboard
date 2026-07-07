import '../../../promotions/domain/entities/pagination_meta.dart';
import '../entities/search_history.dart';
import '../repositories/search_history_repository.dart';

class GetSearchHistoryOverviewUseCase {
  const GetSearchHistoryOverviewUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<SearchHistoryOverviewEntity> call() => _repository.getOverview();
}

class GetSearchHistoryUseCase {
  const GetSearchHistoryUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<PaginatedResult<SearchHistoryEntity>> call(SearchHistoryQuery query) =>
      _repository.getSearchHistory(query);
}

class GetUserSearchHistoryUseCase {
  const GetUserSearchHistoryUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<PaginatedResult<SearchHistoryEntity>> call({
    required String userId,
    required SearchHistoryQuery query,
  }) =>
      _repository.getUserSearchHistory(userId: userId, query: query);
}

class DeleteSearchHistoryUseCase {
  const DeleteSearchHistoryUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<void> call(String id) => _repository.deleteSearchHistoryItem(id);
}

class ClearSearchHistoryUseCase {
  const ClearSearchHistoryUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<void> call({required String userId, String? category}) =>
      _repository.clearUserSearchHistory(userId: userId, category: category);
}

class BulkSearchHistoryUseCase {
  const BulkSearchHistoryUseCase(this._repository);
  final SearchHistoryRepository _repository;

  Future<void> call(SearchHistoryBulkRequest request) =>
      _repository.bulkAction(request);
}
