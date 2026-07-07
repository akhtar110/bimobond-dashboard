import '../../../promotions/domain/entities/pagination_meta.dart';
import '../entities/search_history.dart';

abstract class SearchHistoryRepository {
  Future<SearchHistoryOverviewEntity> getOverview();

  Future<PaginatedResult<SearchHistoryEntity>> getSearchHistory(
    SearchHistoryQuery query,
  );

  Future<PaginatedResult<SearchHistoryEntity>> getUserSearchHistory({
    required String userId,
    required SearchHistoryQuery query,
  });

  Future<void> deleteSearchHistoryItem(String id);

  Future<void> clearUserSearchHistory({
    required String userId,
    String? category,
  });

  Future<void> bulkAction(SearchHistoryBulkRequest request);
}
