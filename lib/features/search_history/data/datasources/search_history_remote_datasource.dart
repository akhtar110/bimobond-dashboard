import 'package:dio/dio.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/search_history.dart';

abstract class SearchHistoryRemoteDataSource {
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

class SearchHistoryRemoteDataSourceImpl implements SearchHistoryRemoteDataSource {
  SearchHistoryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<SearchHistoryOverviewEntity> getOverview() async {
    final response = await _dio.get('/users/admin/search-history/overview');
    return SearchHistoryOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedResult<SearchHistoryEntity>> getSearchHistory(
    SearchHistoryQuery query,
  ) async {
    final response = await _dio.get(
      '/users/admin/search-history',
      queryParameters: query.toQueryParameters(),
    );
    return SearchHistoryPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<PaginatedResult<SearchHistoryEntity>> getUserSearchHistory({
    required String userId,
    required SearchHistoryQuery query,
  }) async {
    final params = Map<String, dynamic>.from(query.toQueryParameters())
      ..remove('userId');
    final response = await _dio.get(
      '/users/admin/$userId/search-history',
      queryParameters: params,
    );
    return SearchHistoryPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<void> deleteSearchHistoryItem(String id) async {
    await _dio.delete('/users/admin/search-history/$id');
  }

  @override
  Future<void> clearUserSearchHistory({
    required String userId,
    String? category,
  }) async {
    await _dio.delete(
      '/users/admin/$userId/search-history',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
  }

  @override
  Future<void> bulkAction(SearchHistoryBulkRequest request) async {
    await _dio.post(
      '/users/admin/search-history/bulk',
      data: request.toJson(),
    );
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    throw Exception('Invalid search history API response');
  }

  Map<String, dynamic> _unwrapPaginated(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid paginated search history response');
    }
    final nested = data['data'];
    if (nested is Map<String, dynamic> && nested['data'] is List) {
      return nested;
    }
    if (data['data'] is List) return data;
    return data;
  }
}

class SearchHistoryOverviewModel extends SearchHistoryOverviewEntity {
  const SearchHistoryOverviewModel({
    required super.totalEntries,
    required super.entriesLast24Hours,
    required super.usersWithHistory,
    required super.byCategory,
    required super.topQueries,
  });

  factory SearchHistoryOverviewModel.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? json;
    final byCategory = (json['byCategory'] as List? ?? [])
        .map(
          (e) => SearchHistoryCategoryCount(
            category: e['category']?.toString() ?? '',
            count: _int(e['count']),
          ),
        )
        .toList();
    final topQueries = (json['topQueries'] as List? ?? [])
        .map(
          (e) => SearchHistoryTopQuery(
            query: e['query']?.toString() ?? '',
            category: e['category']?.toString() ?? '',
            count: _int(e['count']),
          ),
        )
        .toList();

    return SearchHistoryOverviewModel(
      totalEntries: _int(totals['entries']),
      entriesLast24Hours: _int(totals['entriesLast24Hours']),
      usersWithHistory: _int(totals['usersWithHistory']),
      byCategory: byCategory,
      topQueries: topQueries,
    );
  }
}

class SearchHistoryModel extends SearchHistoryEntity {
  const SearchHistoryModel({
    required super.id,
    required super.query,
    required super.category,
    required super.createdAt,
    super.user,
  });

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    SearchHistoryUserSummary? user;
    if (userJson is Map<String, dynamic>) {
      user = SearchHistoryUserSummary(
        id: userJson['id']?.toString() ?? '',
        username: userJson['username']?.toString() ?? '',
        fullName: userJson['fullName']?.toString(),
        email: userJson['email']?.toString(),
        avatarUrl: userJson['avatarUrl']?.toString(),
      );
    }

    return SearchHistoryModel(
      id: json['id']?.toString() ?? '',
      query: json['query']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      user: user,
    );
  }
}

class SearchHistoryPageModel extends PaginatedResult<SearchHistoryEntity> {
  SearchHistoryPageModel({
    required super.data,
    required super.meta,
  });

  factory SearchHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? [])
        .map((e) => SearchHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    return SearchHistoryPageModel(
      data: items,
      meta: PaginationMeta(
        total: _int(metaJson['total']),
        page: _int(metaJson['page']) == 0 ? 1 : _int(metaJson['page']),
        limit: _int(metaJson['limit']) == 0 ? 25 : _int(metaJson['limit']),
        totalPages: () {
          final last = _int(metaJson['lastPage']);
          final total = _int(metaJson['totalPages']);
          final pages = last == 0 ? total : last;
          return pages == 0 ? 1 : pages;
        }(),
      ),
    );
  }
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
