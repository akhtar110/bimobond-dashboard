import 'package:equatable/equatable.dart';

import '../utils/user_history_type_utils.dart';

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
  static const authLogout = 'AUTH_LOGOUT';

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
    this.category,
    this.action,
    this.deviceId,
  });

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final List<String> types;
  final String? category;
  final String? action;
  final String? deviceId;

  bool get hasActiveFilters =>
      from != null ||
      to != null ||
      types.isNotEmpty ||
      (category != null && category!.isNotEmpty) ||
      (action != null && action!.isNotEmpty) ||
      (deviceId != null && deviceId!.isNotEmpty);

  UserHistoryQuery copyWith({
    int? page,
    int? limit,
    DateTime? from,
    DateTime? to,
    List<String>? types,
    String? category,
    String? action,
    String? deviceId,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearTypes = false,
    bool clearCategory = false,
    bool clearAction = false,
    bool clearDeviceId = false,
    bool clearDateRange = false,
  }) {
    return UserHistoryQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      from: clearDateRange || clearFrom ? null : (from ?? this.from),
      to: clearDateRange || clearTo ? null : (to ?? this.to),
      types: clearTypes ? const [] : (types ?? this.types),
      category: clearCategory ? null : (category ?? this.category),
      action: clearAction ? null : (action ?? this.action),
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
    );
  }

  Map<String, dynamic> toQueryParameters({bool forTimeline = false}) {
    final fromIso = from != null ? _toIso(from!) : null;
    final toIso = to != null ? _toIsoEndOfDay(to!) : null;

    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (fromIso != null) ...{
        'from': fromIso,
        'startDate': fromIso,
      },
      if (toIso != null) ...{
        'to': toIso,
        'endDate': toIso,
      },
      if (category != null && category!.isNotEmpty) 'category': category,
      if (action != null && action!.isNotEmpty) 'action': action,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    };

    if (types.isEmpty) return params;

    if (forTimeline) {
      params['types'] = types.join(',');
      if (types.length == 1) {
        params['type'] = types.first;
      }
      return params;
    }

    if (types.length == 1) {
      final audit = userHistoryAuditFilterForType(types.first);
      if (audit != null) {
        params['category'] = audit.category;
        params['action'] = audit.action;
      }
    }

    return params;
  }

  bool get prefersTimelineEndpoint => userHistoryQueryPrefersTimeline(this);

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
  List<Object?> get props => [page, limit, from, to, types, category, action, deviceId];
}
