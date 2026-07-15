import '../../domain/entities/search_management_entities.dart';
import '../../domain/repositories/search_management_repository.dart';
import '../datasources/search_management_remote_datasource.dart';

class SearchManagementRepositoryImpl implements SearchManagementRepository {
  const SearchManagementRepositoryImpl(this._dataSource);

  final SearchManagementRemoteDataSource _dataSource;

  @override
  Future<UnifiedSearchResult> search(SearchManagementFilterQuery query) {
    return _dataSource.search(query);
  }

  @override
  Future<List<SearchTrendEntity>> getTrends({
    String? search,
    String? countryCode,
  }) {
    return _dataSource.getTrends(
      search: search,
      countryCode: countryCode,
    );
  }

  @override
  Future<SearchHistoryPageResult> getMySearchHistory({
    String? category,
    int page = 1,
    int limit = 20,
  }) {
    return _dataSource.getMySearchHistory(
      category: category,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<void> saveSearchHistory({
    required String query,
    String category = 'ALL',
  }) {
    return _dataSource.saveSearchHistory(query: query, category: category);
  }

  @override
  Future<void> clearMySearchHistory({String? category}) {
    return _dataSource.clearMySearchHistory(category: category);
  }

  @override
  Future<SearchHistoryPageResult> getAdminSearchHistory({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 25,
  }) {
    return _dataSource.getAdminSearchHistory(
      search: search,
      category: category,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<SearchManagementOverviewEntity> getOverviewStats({
    String seedQuery = 'a',
  }) {
    return _dataSource.getOverviewStats(seedQuery: seedQuery);
  }
}
