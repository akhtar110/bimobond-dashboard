import 'package:dio/dio.dart';

import '../../domain/entities/search_management_entities.dart';
import '../models/search_management_models.dart';

abstract class SearchManagementRemoteDataSource {
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

class SearchManagementRemoteDataSourceImpl
    implements SearchManagementRemoteDataSource {
  SearchManagementRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UnifiedSearchResult> search(SearchManagementFilterQuery query) async {
    final response = await _dio.get(
      '/search',
      queryParameters: query.toSearchParams(),
    );
    return UnifiedSearchResultModel.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<List<SearchTrendEntity>> getTrends({
    String? search,
    String? countryCode,
  }) async {
    final response = await _dio.get(
      '/users/me/search-trends',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (countryCode != null && countryCode.isNotEmpty)
          'countryCode': countryCode,
      },
    );
    return SearchTrendModel.listFromJson(response.data);
  }

  @override
  Future<SearchHistoryPageResult> getMySearchHistory({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/me/search-history',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'limit': limit,
      },
    );
    return SearchHistoryPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<void> saveSearchHistory({
    required String query,
    String category = 'ALL',
  }) async {
    await _dio.post(
      '/users/me/search-history',
      data: {
        'query': query,
        'category': category,
      },
    );
  }

  @override
  Future<void> clearMySearchHistory({String? category}) async {
    await _dio.delete(
      '/users/me/search-history',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
  }

  @override
  Future<SearchHistoryPageResult> getAdminSearchHistory({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await _dio.get(
      '/users/admin/search-history',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        'sort': 'NEWEST',
      },
    );
    return SearchHistoryPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<SearchManagementOverviewEntity> getOverviewStats({
    String seedQuery = 'a',
  }) async {
    SearchManagementOverviewEntity? fromAdmin;
    try {
      final overviewRes =
          await _dio.get('/users/admin/search-history/overview');
      final map = _unwrapMap(overviewRes.data);
      final topQueries = map['topQueries'];
      String? topQuery;
      if (topQueries is List && topQueries.isNotEmpty) {
        final first = topQueries.first;
        if (first is Map) {
          topQuery = first['query']?.toString();
        }
      }
      fromAdmin = SearchManagementOverviewEntity(
        totalSearches: _readInt(map['totalEntries']),
        totalUsers: _readInt(map['usersWithHistory']),
        totalPosts: 0,
        totalSounds: 0,
        totalHashtags: 0,
        trendingCount: topQueries is List ? topQueries.length : 0,
        topQuery: topQuery,
      );
    } catch (_) {
      fromAdmin = null;
    }

    UnifiedSearchResult? live;
    List<SearchTrendEntity> trends = const [];
    try {
      live = await search(
        SearchManagementFilterQuery(
          q: seedQuery,
          apiTab: SearchApiTab.best,
          limit: 5,
        ),
      );
    } catch (_) {}

    try {
      trends = await getTrends();
    } catch (_) {}

    return SearchManagementOverviewEntity(
      totalSearches:
          fromAdmin?.totalSearches ?? (live?.totalResults ?? 0),
      totalUsers: live?.totalUsers ?? fromAdmin?.totalUsers ?? 0,
      totalPosts: live?.totalPosts ?? 0,
      totalSounds: live?.totalSounds ?? 0,
      totalHashtags: live?.totalHashtags ?? 0,
      trendingCount: trends.isNotEmpty
          ? trends.length
          : (fromAdmin?.trendingCount ?? 0),
      topQuery: trends.isNotEmpty
          ? trends.first.query
          : fromAdmin?.topQuery,
    );
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw Exception('Invalid search API response');
  }

  Map<String, dynamic> _unwrapPaginated(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') || data.containsKey('meta')) return data;
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    if (data is List) {
      return {
        'data': data,
        'meta': {
          'total': data.length,
          'page': 1,
          'limit': data.length,
          'totalPages': 1,
        },
      };
    }
    throw Exception('Invalid paginated search response');
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
