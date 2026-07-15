import '../../../../core/utils/media_url_resolver.dart';
import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/search_management_entities.dart';

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

SearchSectionMeta _metaFromJson(Map<String, dynamic>? json, {int fallbackLimit = 20}) {
  if (json == null) {
    return SearchSectionMeta(total: 0, page: 1, limit: fallbackLimit);
  }
  return SearchSectionMeta(
    total: _toInt(json['total']),
    page: _toInt(json['page'] ?? 1),
    limit: _toInt(json['limit'] ?? fallbackLimit),
    totalPages: json['totalPages'] == null && json['lastPage'] == null
        ? null
        : _toInt(json['totalPages'] ?? json['lastPage']),
  );
}

class SearchPostHitModel {
  static SearchPostHit fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SearchPostHit(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? json['caption']?.toString(),
      thumbnailUrl: resolveMediaUrl(
        json['thumbnailUrl']?.toString() ??
            json['animatedCoverUrl']?.toString() ??
            json['videoUrl']?.toString(),
      ),
      type: json['type']?.toString(),
      viewCount: _toInt(json['viewCount']),
      likeCount: _toInt(json['likeCount']),
      createdAt: _toDate(json['createdAt']),
      username: user?['username']?.toString(),
    );
  }
}

class SearchUserHitModel {
  static SearchUserHit fromJson(Map<String, dynamic> json) {
    return SearchUserHit(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'user',
      fullName: json['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(json['avatarUrl']?.toString()),
      isVerified: json['isVerified'] == true,
      followerCount: _toInt(json['followerCount']),
      postCount: _toInt(json['postCount']),
    );
  }
}

class SearchSoundHitModel {
  static SearchSoundHit fromJson(Map<String, dynamic> json) {
    return SearchSoundHit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sound',
      author: json['author']?.toString() ?? json['creator']?.toString(),
      audioUrl: resolveMediaUrl(json['audioUrl']?.toString()),
      coverUrl: resolveMediaUrl(json['coverUrl']?.toString()),
      useCount: _toInt(json['useCount'] ?? json['usageCount']),
      duration: json['duration'] == null ? null : _toInt(json['duration']),
    );
  }
}

class SearchHashtagHitModel {
  static SearchHashtagHit fromJson(Map<String, dynamic> json) {
    return SearchHashtagHit(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      viewCount: _toInt(json['viewCount']),
      postCount: _toInt(json['postCount'] ?? json['count']),
    );
  }
}

SearchSection<T> _sectionFromJson<T>(
  dynamic section,
  T Function(Map<String, dynamic>) mapper,
) {
  if (section is! Map<String, dynamic>) {
    if (section is List) {
      final items = section
          .whereType<Map>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList();
      return SearchSection(
        data: items,
        meta: SearchSectionMeta(
          total: items.length,
          page: 1,
          limit: items.length,
        ),
      );
    }
    return const SearchSection(
      data: [],
      meta: SearchSectionMeta(total: 0, page: 1, limit: 20),
    );
  }

  final rawData = section['data'] ?? section['items'] ?? section['results'];
  final list = rawData is List
      ? rawData
          .whereType<Map>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList()
      : <T>[];
  final metaRaw = section['meta'];
  return SearchSection(
    data: list,
    meta: _metaFromJson(
      metaRaw is Map<String, dynamic> ? metaRaw : null,
      fallbackLimit: list.isEmpty ? 20 : list.length,
    ),
  );
}

class UnifiedSearchResultModel {
  static UnifiedSearchResult fromJson(Map<String, dynamic> json) {
    return UnifiedSearchResult(
      q: json['q']?.toString() ?? '',
      tab: SearchApiTab.fromApi(json['tab']?.toString()),
      posts: json.containsKey('posts')
          ? _sectionFromJson(json['posts'], SearchPostHitModel.fromJson)
          : null,
      users: json.containsKey('users')
          ? _sectionFromJson(json['users'], SearchUserHitModel.fromJson)
          : null,
      sounds: json.containsKey('sounds')
          ? _sectionFromJson(json['sounds'], SearchSoundHitModel.fromJson)
          : null,
      hashtags: json.containsKey('hashtags')
          ? _sectionFromJson(json['hashtags'], SearchHashtagHitModel.fromJson)
          : null,
    );
  }
}

class SearchTrendModel {
  static SearchTrendEntity fromJson(Map<String, dynamic> json) {
    return SearchTrendEntity(
      query: json['query']?.toString() ??
          json['q']?.toString() ??
          json['term']?.toString() ??
          '',
      category: json['category']?.toString(),
      count: _toInt(json['count'] ?? json['searches'] ?? json['searchCount']),
      score: _toDouble(json['score'] ?? json['trendingScore']),
      countryCode: json['countryCode']?.toString(),
      city: json['city']?.toString(),
    );
  }

  static List<SearchTrendEntity> listFromJson(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.query.isNotEmpty)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final nested = data['trends'] ??
          data['data'] ??
          data['items'] ??
          data['results'];
      return listFromJson(nested);
    }
    return const [];
  }
}

class SearchHistoryEntryModel {
  static SearchHistoryEntryEntity fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SearchHistoryEntryEntity(
      id: json['id']?.toString() ?? '',
      query: json['query']?.toString() ?? '',
      category: json['category']?.toString() ?? 'ALL',
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      userId: json['userId']?.toString() ?? user?['id']?.toString(),
      username: user?['username']?.toString(),
    );
  }
}

class SearchHistoryPageModel {
  static SearchHistoryPageResult fromJson(Map<String, dynamic> json) {
    final raw = json['data'] ??
        json['items'] ??
        json['history'] ??
        json['entries'] ??
        const [];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => SearchHistoryEntryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <SearchHistoryEntryEntity>[];
    final metaRaw = json['meta'];
    final metaMap = metaRaw is Map<String, dynamic> ? metaRaw : const {};
    return SearchHistoryPageResult(
      data: list,
      meta: PaginationMeta(
        total: _toInt(metaMap['total'] ?? list.length),
        page: _toInt(metaMap['page'] ?? 1),
        limit: _toInt(metaMap['limit'] ?? 25),
        totalPages: _toInt(
          metaMap['totalPages'] ?? metaMap['lastPage'] ?? 1,
        ),
      ),
    );
  }
}
