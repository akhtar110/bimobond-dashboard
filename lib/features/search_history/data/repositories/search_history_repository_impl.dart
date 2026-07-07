import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/search_history.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../datasources/search_history_remote_datasource.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  const SearchHistoryRepositoryImpl(this._remote);

  final SearchHistoryRemoteDataSource _remote;

  @override
  Future<SearchHistoryOverviewEntity> getOverview() => _remote.getOverview();

  @override
  Future<PaginatedResult<SearchHistoryEntity>> getSearchHistory(
    SearchHistoryQuery query,
  ) =>
      _remote.getSearchHistory(query);

  @override
  Future<PaginatedResult<SearchHistoryEntity>> getUserSearchHistory({
    required String userId,
    required SearchHistoryQuery query,
  }) =>
      _remote.getUserSearchHistory(userId: userId, query: query);

  @override
  Future<void> deleteSearchHistoryItem(String id) =>
      _remote.deleteSearchHistoryItem(id);

  @override
  Future<void> clearUserSearchHistory({
    required String userId,
    String? category,
  }) =>
      _remote.clearUserSearchHistory(userId: userId, category: category);

  @override
  Future<void> bulkAction(SearchHistoryBulkRequest request) =>
      _remote.bulkAction(request);
}
