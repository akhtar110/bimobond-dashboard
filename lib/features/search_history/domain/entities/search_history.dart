import 'package:equatable/equatable.dart';

class SearchHistoryEntity extends Equatable {
  const SearchHistoryEntity({
    required this.id,
    required this.query,
    required this.category,
    required this.createdAt,
    this.user,
  });

  final String id;
  final String query;
  final String category;
  final DateTime createdAt;
  final SearchHistoryUserSummary? user;

  @override
  List<Object?> get props => [id, query, category, createdAt, user];
}

class SearchHistoryUserSummary extends Equatable {
  const SearchHistoryUserSummary({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, username, fullName, email, avatarUrl];
}

class SearchHistoryCategoryCount extends Equatable {
  const SearchHistoryCategoryCount({
    required this.category,
    required this.count,
  });

  final String category;
  final int count;

  @override
  List<Object?> get props => [category, count];
}

class SearchHistoryTopQuery extends Equatable {
  const SearchHistoryTopQuery({
    required this.query,
    required this.category,
    required this.count,
  });

  final String query;
  final String category;
  final int count;

  @override
  List<Object?> get props => [query, category, count];
}

class SearchHistoryOverviewEntity extends Equatable {
  const SearchHistoryOverviewEntity({
    required this.totalEntries,
    required this.entriesLast24Hours,
    required this.usersWithHistory,
    required this.byCategory,
    required this.topQueries,
  });

  final int totalEntries;
  final int entriesLast24Hours;
  final int usersWithHistory;
  final List<SearchHistoryCategoryCount> byCategory;
  final List<SearchHistoryTopQuery> topQueries;

  String? get topQueryLabel =>
      topQueries.isNotEmpty ? topQueries.first.query : null;

  @override
  List<Object?> get props => [
        totalEntries,
        entriesLast24Hours,
        usersWithHistory,
        byCategory,
        topQueries,
      ];
}

enum SearchHistorySort {
  newest('NEWEST'),
  oldest('OLDEST'),
  queryAsc('QUERY_ASC'),
  queryDesc('QUERY_DESC');

  const SearchHistorySort(this.apiValue);
  final String apiValue;
}

class SearchHistoryQuery extends Equatable {
  const SearchHistoryQuery({
    this.page = 1,
    this.limit = 25,
    this.search,
    this.category,
    this.userId,
    this.from,
    this.to,
    this.sort = SearchHistorySort.newest,
  });

  final int page;
  final int limit;
  final String? search;
  final String? category;
  final String? userId;
  final DateTime? from;
  final DateTime? to;
  final SearchHistorySort sort;

  SearchHistoryQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? category,
    String? userId,
    DateTime? from,
    DateTime? to,
    SearchHistorySort? sort,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearUserId = false,
    bool clearDateRange = false,
  }) {
    return SearchHistoryQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      category: clearCategory ? null : (category ?? this.category),
      userId: clearUserId ? null : (userId ?? this.userId),
      from: clearDateRange ? null : (from ?? this.from),
      to: clearDateRange ? null : (to ?? this.to),
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      'sort': sort.apiValue,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (category != null && category!.isNotEmpty) 'category': category,
      if (userId != null && userId!.isNotEmpty) 'userId': userId,
      if (from != null) 'from': from!.toUtc().toIso8601String(),
      if (to != null) 'to': to!.toUtc().toIso8601String(),
    };
  }

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      (category != null && category!.isNotEmpty) ||
      (userId != null && userId!.isNotEmpty) ||
      from != null ||
      to != null;

  @override
  List<Object?> get props =>
      [page, limit, search, category, userId, from, to, sort];
}

enum SearchHistoryBulkAction {
  delete('DELETE'),
  clearUsers('CLEAR_USERS');

  const SearchHistoryBulkAction(this.apiValue);
  final String apiValue;
}

class SearchHistoryBulkRequest extends Equatable {
  const SearchHistoryBulkRequest({
    required this.action,
    this.searchHistoryIds = const [],
    this.userIds = const [],
    this.category,
  });

  final SearchHistoryBulkAction action;
  final List<String> searchHistoryIds;
  final List<String> userIds;
  final String? category;

  Map<String, dynamic> toJson() {
    return {
      'action': action.apiValue,
      if (searchHistoryIds.isNotEmpty) 'searchHistoryIds': searchHistoryIds,
      if (userIds.isNotEmpty) 'userIds': userIds,
      if (category != null && category!.isNotEmpty) 'category': category,
    };
  }

  @override
  List<Object?> get props => [action, searchHistoryIds, userIds, category];
}

abstract final class SearchHistoryCategories {
  static const all = 'ALL';
  static const posts = 'POSTS';
  static const auctions = 'AUCTIONS';
  static const users = 'USERS';
  static const sounds = 'SOUNDS';
  static const hashtags = 'HASHTAGS';
  static const lives = 'LIVES';
  static const chats = 'CHATS';

  static const filterOptions = [
    posts,
    auctions,
    users,
    sounds,
    hashtags,
    lives,
    chats,
  ];
}
