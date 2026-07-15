import '../entities/search_management_entities.dart';

abstract class SearchManagementRepository {
  Future<UnifiedSearchResult> search(SearchManagementFilterQuery query);

  Future<List<SearchTrendEntity>> getTrends({
    String? search,
    String? countryCode,
  });

  Future<SearchHistoryPageResult> getMySearchHistory({
    String? category,
    int page = 1,
    int limit = 20,
  });

  Future<void> saveSearchHistory({
    required String query,
    String category = 'ALL',
  });

  Future<void> clearMySearchHistory({String? category});

  Future<SearchHistoryPageResult> getAdminSearchHistory({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 25,
  });

  Future<SearchManagementOverviewEntity> getOverviewStats({
    String seedQuery = 'a',
  });
}
