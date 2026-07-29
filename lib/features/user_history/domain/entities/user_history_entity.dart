import 'package:equatable/equatable.dart';

/// Single merged timeline entry from `GET /activity/admin/users/:id/timeline`.
class UserHistoryEntity extends Equatable {
  const UserHistoryEntity({
    required this.type,
    required this.createdAt,
    required this.data,
  });

  final String type;
  final DateTime createdAt;

  /// Raw payload for the entry (`data` field from the API).
  final Map<String, dynamic> data;

  String get normalizedType => type.toUpperCase();

  String? dataString(String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  num? dataNum(String key) {
    final value = data[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic>? dataMap(String key) {
    final value = data[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? nestedString(String mapKey, String field) {
    final map = dataMap(mapKey);
    if (map == null) return null;
    final value = map[field];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [type, createdAt, data];
}

class UserHistoryMetaEntity extends Equatable {
  const UserHistoryMetaEntity({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.note,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? note;

  bool get hasReachedMax => page >= totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages, note];
}

class UserHistoryPageEntity extends Equatable {
  const UserHistoryPageEntity({
    required this.items,
    required this.meta,
  });

  final List<UserHistoryEntity> items;
  final UserHistoryMetaEntity meta;

  @override
  List<Object?> get props => [items, meta];
}

/// Supported timeline `type` values from the Activity Admin API.
abstract final class UserHistoryTypes {
  static const profileView = 'PROFILE_VIEW';
  static const screenView = 'SCREEN_VIEW';
  static const share = 'SHARE';
  static const profileVisitGiven = 'PROFILE_VISIT_GIVEN';
  static const profileVisitReceived = 'PROFILE_VISIT_RECEIVED';
  static const createPost = 'CREATE_POST';
  static const likePost = 'LIKE_POST';
  static const comment = 'COMMENT';
  static const repost = 'REPOST';
  static const sendGift = 'SEND_GIFT';
  static const postView = 'POST_VIEW';
  static const save = 'SAVE';
  static const storyView = 'STORY_VIEW';
  static const search = 'SEARCH';
  static const location = 'LOCATION';
  static const authLogin = 'AUTH_LOGIN';

  static const all = <String>[
    profileView,
    screenView,
    share,
    profileVisitGiven,
    profileVisitReceived,
    createPost,
    likePost,
    comment,
    repost,
    sendGift,
    postView,
    save,
    storyView,
    search,
    location,
  ];

  /// Types offered in the User History activity-type filter.
  /// Excludes client analytics events that are not useful as admin filters.
  static const filterOptions = <String>[
    share,
    profileVisitGiven,
    profileVisitReceived,
    createPost,
    likePost,
    comment,
    repost,
    sendGift,
    postView,
    save,
    storyView,
    search,
    location,
  ];
}

class UserHistoryQuery extends Equatable {
  const UserHistoryQuery({
    this.page = 1,
    this.limit = 30,
    this.from,
    this.to,
    this.types = const [],
  });

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final List<String> types;

  bool get hasActiveFilters =>
      from != null || to != null || types.isNotEmpty;

  UserHistoryQuery copyWith({
    int? page,
    int? limit,
    DateTime? from,
    DateTime? to,
    List<String>? types,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearTypes = false,
    bool clearDateRange = false,
  }) {
    return UserHistoryQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      from: clearDateRange || clearFrom ? null : (from ?? this.from),
      to: clearDateRange || clearTo ? null : (to ?? this.to),
      types: clearTypes ? const [] : (types ?? this.types),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (from != null) 'from': _toIso(from!),
      if (to != null) 'to': _toIsoEndOfDay(to!),
      if (types.isNotEmpty) 'types': types.join(','),
    };
  }

  static String _toIso(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    return utc.toIso8601String();
  }

  static String _toIsoEndOfDay(DateTime value) {
    final utc = DateTime.utc(
      value.year,
      value.month,
      value.day,
      23,
      59,
      59,
      999,
    );
    return utc.toIso8601String();
  }

  @override
  List<Object?> get props => [page, limit, from, to, types];
}
