import '../entities/search_management_entities.dart';
import '../repositories/search_management_repository.dart';

class SearchUnifiedUseCase {
  const SearchUnifiedUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<UnifiedSearchResult> call(SearchManagementFilterQuery query) {
    return _repository.search(query);
  }
}

class GetSearchTrendsUseCase {
  const GetSearchTrendsUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<List<SearchTrendEntity>> call({
    String? search,
    String? countryCode,
  }) {
    return _repository.getTrends(
      search: search,
      countryCode: countryCode,
    );
  }
}

class GetMySearchHistoryUseCase {
  const GetMySearchHistoryUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<SearchHistoryPageResult> call({
    String? category,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getMySearchHistory(
      category: category,
      page: page,
      limit: limit,
    );
  }
}

class SaveSearchHistoryUseCase {
  const SaveSearchHistoryUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<void> call({
    required String query,
    String category = 'ALL',
  }) {
    return _repository.saveSearchHistory(query: query, category: category);
  }
}

class ClearMySearchHistoryUseCase {
  const ClearMySearchHistoryUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<void> call({String? category}) {
    return _repository.clearMySearchHistory(category: category);
  }
}

class GetAdminSearchHistoryUseCase {
  const GetAdminSearchHistoryUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<SearchHistoryPageResult> call({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 25,
  }) {
    return _repository.getAdminSearchHistory(
      search: search,
      category: category,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
  }
}

class GetSearchManagementOverviewUseCase {
  const GetSearchManagementOverviewUseCase(this._repository);

  final SearchManagementRepository _repository;

  Future<SearchManagementOverviewEntity> call({String seedQuery = 'a'}) {
    return _repository.getOverviewStats(seedQuery: seedQuery);
  }
}
