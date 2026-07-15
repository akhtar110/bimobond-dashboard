import 'package:equatable/equatable.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';

enum SearchManagementTab {
  overview,
  searches,
  users,
  sounds,
  hashtags,
  trends,
}

enum SearchApiTab {
  best('BEST'),
  posts('POSTS'),
  users('USERS'),
  sounds('SOUNDS'),
  hashtags('HASHTAGS');

  const SearchApiTab(this.apiValue);
  final String apiValue;

  static SearchApiTab fromApi(String? raw) {
    final value = (raw ?? '').toUpperCase();
    return SearchApiTab.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => SearchApiTab.best,
    );
  }
}

enum SearchManagementSort {
  relevance('RELEVANCE'),
  newest('NEWEST'),
  oldest('OLDEST'),
  popularity('POPULARITY');

  const SearchManagementSort(this.apiValue);
  final String apiValue;
}

class SearchSectionMeta extends Equatable {
  const SearchSectionMeta({
    required this.total,
    required this.page,
    required this.limit,
    this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int? totalPages;

  bool get hasMore {
    if (totalPages != null) return page < totalPages!;
    return page * limit < total;
  }

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

class SearchSection<T> extends Equatable {
  const SearchSection({
    required this.data,
    required this.meta,
  });

  final List<T> data;
  final SearchSectionMeta meta;

  @override
  List<Object?> get props => [data, meta];
}

class SearchPostHit extends Equatable {
  const SearchPostHit({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.type,
    this.viewCount = 0,
    this.likeCount = 0,
    this.createdAt,
    this.username,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final String? type;
  final int viewCount;
  final int likeCount;
  final DateTime? createdAt;
  final String? username;

  @override
  List<Object?> get props =>
      [id, description, thumbnailUrl, type, viewCount, likeCount, createdAt, username];
}

class SearchUserHit extends Equatable {
  const SearchUserHit({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.followerCount = 0,
    this.postCount = 0,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final int followerCount;
  final int postCount;

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    return username;
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, avatarUrl, isVerified, followerCount, postCount];
}

class SearchSoundHit extends Equatable {
  const SearchSoundHit({
    required this.id,
    required this.name,
    this.author,
    this.audioUrl,
    this.coverUrl,
    this.useCount = 0,
    this.duration,
  });

  final String id;
  final String name;
  final String? author;
  final String? audioUrl;
  final String? coverUrl;
  final int useCount;
  final int? duration;

  @override
  List<Object?> get props =>
      [id, name, author, audioUrl, coverUrl, useCount, duration];
}

class SearchHashtagHit extends Equatable {
  const SearchHashtagHit({
    required this.id,
    required this.name,
    this.viewCount = 0,
    this.postCount = 0,
  });

  final String id;
  final String name;
  final int viewCount;
  final int postCount;

  @override
  List<Object?> get props => [id, name, viewCount, postCount];
}

class UnifiedSearchResult extends Equatable {
  const UnifiedSearchResult({
    required this.q,
    required this.tab,
    this.posts,
    this.users,
    this.sounds,
    this.hashtags,
  });

  final String q;
  final SearchApiTab tab;
  final SearchSection<SearchPostHit>? posts;
  final SearchSection<SearchUserHit>? users;
  final SearchSection<SearchSoundHit>? sounds;
  final SearchSection<SearchHashtagHit>? hashtags;

  int get totalPosts => posts?.meta.total ?? 0;
  int get totalUsers => users?.meta.total ?? 0;
  int get totalSounds => sounds?.meta.total ?? 0;
  int get totalHashtags => hashtags?.meta.total ?? 0;
  int get totalResults =>
      totalPosts + totalUsers + totalSounds + totalHashtags;

  @override
  List<Object?> get props => [q, tab, posts, users, sounds, hashtags];
}

class SearchTrendEntity extends Equatable {
  const SearchTrendEntity({
    required this.query,
    this.category,
    this.count = 0,
    this.score,
    this.countryCode,
    this.city,
  });

  final String query;
  final String? category;
  final int count;
  final double? score;
  final String? countryCode;
  final String? city;

  @override
  List<Object?> get props =>
      [query, category, count, score, countryCode, city];
}

class SearchHistoryEntryEntity extends Equatable {
  const SearchHistoryEntryEntity({
    required this.id,
    required this.query,
    required this.category,
    required this.createdAt,
    this.userId,
    this.username,
  });

  final String id;
  final String query;
  final String category;
  final DateTime createdAt;
  final String? userId;
  final String? username;

  @override
  List<Object?> get props =>
      [id, query, category, createdAt, userId, username];
}

class SearchManagementOverviewEntity extends Equatable {
  const SearchManagementOverviewEntity({
    required this.totalSearches,
    required this.totalUsers,
    required this.totalPosts,
    required this.totalSounds,
    required this.totalHashtags,
    required this.trendingCount,
    this.topQuery,
  });

  final int totalSearches;
  final int totalUsers;
  final int totalPosts;
  final int totalSounds;
  final int totalHashtags;
  final int trendingCount;
  final String? topQuery;

  @override
  List<Object?> get props => [
        totalSearches,
        totalUsers,
        totalPosts,
        totalSounds,
        totalHashtags,
        trendingCount,
        topQuery,
      ];
}

class SearchManagementFilterQuery extends Equatable {
  const SearchManagementFilterQuery({
    this.q = '',
    this.apiTab = SearchApiTab.best,
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.sort = SearchManagementSort.relevance,
    this.trendingOnly = false,
  });

  final String q;
  final SearchApiTab apiTab;
  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final SearchManagementSort sort;
  final bool trendingOnly;

  bool get hasActiveFilters =>
      q.trim().isNotEmpty ||
      apiTab != SearchApiTab.best ||
      from != null ||
      to != null ||
      sort != SearchManagementSort.relevance ||
      trendingOnly;

  SearchManagementFilterQuery copyWith({
    String? q,
    SearchApiTab? apiTab,
    int? page,
    int? limit,
    DateTime? from,
    DateTime? to,
    SearchManagementSort? sort,
    bool? trendingOnly,
    bool clearDateRange = false,
  }) {
    return SearchManagementFilterQuery(
      q: q ?? this.q,
      apiTab: apiTab ?? this.apiTab,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      from: clearDateRange ? null : (from ?? this.from),
      to: clearDateRange ? null : (to ?? this.to),
      sort: sort ?? this.sort,
      trendingOnly: trendingOnly ?? this.trendingOnly,
    );
  }

  Map<String, dynamic> toSearchParams() {
    return {
      'q': q.trim().isEmpty ? 'a' : q.trim(),
      'tab': apiTab.apiValue,
      'page': page,
      'limit': limit,
    };
  }

  @override
  List<Object?> get props =>
      [q, apiTab, page, limit, from, to, sort, trendingOnly];
}

class SearchHistoryPageResult extends Equatable {
  const SearchHistoryPageResult({
    required this.data,
    required this.meta,
  });

  final List<SearchHistoryEntryEntity> data;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}
