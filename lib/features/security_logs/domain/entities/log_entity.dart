import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/user_entity.dart';

/// Single row from `GET /user-history/admin/logs` (`UserHistoryLog`).
class LogEntity extends Equatable {
  const LogEntity({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.action,
    this.actorId,
    this.actorRole,
    this.userFullName,
    this.userName,
    this.userEmail,
    this.avatarUrl,
    this.targetType,
    this.targetId,
    this.meta,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.permission,
    this.raw = const {},
  });

  final String id;
  final DateTime createdAt;

  /// Activity category: AUTH, SOCIAL, CONTENT, …
  final String category;

  /// Canonical action code: AUTH_LOGIN, FOLLOW, ADMIN_ACTION, …
  final String action;

  final String? actorId;

  /// Actor role: USER | ADMIN | SYSTEM
  final String? actorRole;

  final String? userFullName;
  final String? userName;
  final String? userEmail;
  final String? avatarUrl;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? meta;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? permission;

  /// Original payload for detail views / unknown fields.
  final Map<String, dynamic> raw;

  /// Prefer full name for table display; fall back gracefully.
  String get displayUser {
    final fullName = userFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = userEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return '';
  }

  /// Username shown when it adds info beyond [displayUser].
  String? get secondaryUserLabel {
    final name = userName?.trim();
    if (name == null || name.isEmpty) return null;
    final primary = displayUser;
    if (primary.isEmpty || primary == name) return null;
    return '@$name';
  }

  String? get displayTarget {
    final type = targetType?.trim();
    final id = targetId?.trim();
    if ((type == null || type.isEmpty) && (id == null || id.isEmpty)) {
      return null;
    }
    if (type != null && type.isNotEmpty && id != null && id.isNotEmpty) {
      return '$type · $id';
    }
    return type ?? id;
  }

  /// Back-compat alias used by older UI helpers.
  String? get userId => actorId;

  String? get device => deviceId ?? userAgent;

  @override
  List<Object?> get props => [
        id,
        createdAt,
        category,
        action,
        actorId,
        actorRole,
        userFullName,
        userName,
        userEmail,
        targetType,
        targetId,
        ipAddress,
        userAgent,
        deviceId,
        permission,
      ];
}

class LogsQuery extends Equatable {
  const LogsQuery({
    this.page = 1,
    this.limit = 50,
    this.userId,
    this.user,
    this.actorRole,
    this.category,
    this.action,
    this.from,
    this.to,
    this.deviceId,
  });

  final int page;
  final int limit;
  final String? userId;
  final UserEntity? user;

  /// `USER` | `ADMIN` | `SYSTEM`
  final String? actorRole;

  /// AUTH, SOCIAL, CONTENT, …
  final String? category;

  /// Exact action code.
  final String? action;

  final DateTime? from;
  final DateTime? to;
  final String? deviceId;

  static const pageSizeOptions = <int>[10, 20, 50, 100];

  static const actorRoleOptions = <String>['USER', 'ADMIN', 'SYSTEM'];

  static const categoryOptions = <String>[
    'AUTH',
    'SOCIAL',
    'CONTENT',
    'COMMERCE',
    'MESSAGING',
    'MODERATION',
    'ADMIN',
    'NAVIGATION',
    'SETTINGS',
  ];

  /// Canonical action codes grouped by category (README).
  static const actionsByCategory = <String, List<String>>{
    'AUTH': [
      'AUTH_LOGIN',
      'AUTH_LOGOUT',
      'AUTH_REGISTER',
      'AUTH_PASSWORD_RESET',
      'AUTH_OTP_VERIFY',
    ],
    'SOCIAL': [
      'FOLLOW',
      'UNFOLLOW',
      'FOLLOW_REQUEST_SEND',
      'FOLLOW_REQUEST_CANCEL',
      'FOLLOW_REQUEST_ACCEPT',
      'FOLLOW_REQUEST_REJECT',
      'MUTE_USER',
      'UNMUTE_USER',
      'RESTRICT_USER',
      'UNRESTRICT_USER',
      'BLOCK_USER',
      'UNBLOCK_USER',
      'REMOVE_FOLLOWER',
    ],
    'CONTENT': [
      'POST_CREATE',
      'POST_DELETE',
      'POST_LIKE',
      'POST_UNLIKE',
      'POST_SAVE',
      'POST_UNSAVE',
      'POST_SHARE',
      'POST_REPOST',
      'POST_UNREPOST',
      'POST_NOT_INTERESTED',
      'COMMENT_CREATE',
      'COMMENT_DELETE',
      'STORY_CREATE',
    ],
    'COMMERCE': ['GIFT_SEND'],
    'MESSAGING': ['MESSAGE_SEND'],
    'MODERATION': [
      'REPORT_CREATE',
      // Ban + Unban logs are fetched via `?action=USER_BAN`.
      'USER_BAN',
    ],
    'NAVIGATION': ['PROFILE_VIEW', 'SCREEN_VIEW', 'SEARCH'],
    'SETTINGS': ['PROFILE_UPDATE', 'LOCATION_UPDATE'],
    'ADMIN': [
      'ADMIN_ACTION',
      // Same code as MODERATION; `actionsForCategory(null)` de-dupes.
      'USER_BAN',
    ],
  };

  static List<String> actionsForCategory(String? category) {
    final key = category?.trim().toUpperCase();
    if (key != null && actionsByCategory.containsKey(key)) {
      return actionsByCategory[key]!;
    }
    final seen = <String>{};
    final all = <String>[];
    for (final actions in actionsByCategory.values) {
      for (final action in actions) {
        if (seen.add(action)) all.add(action);
      }
    }
    return all;
  }

  bool get hasActiveFilters =>
      (userId != null && userId!.trim().isNotEmpty) ||
      (actorRole != null && actorRole!.trim().isNotEmpty) ||
      (category != null && category!.trim().isNotEmpty) ||
      (action != null && action!.trim().isNotEmpty) ||
      from != null ||
      to != null;

  static String? _iso(DateTime? value) {
    if (value == null) return null;
    return value.toUtc().toIso8601String();
  }

  Map<String, dynamic> toQueryParameters() {
    final resolvedUserId = (userId ?? user?.id)?.trim();
    final role = actorRole?.trim().toUpperCase();
    final cat = category?.trim().toUpperCase();
    // Canonicalize ban aliases to the API codes used by admin logs.
    final act = _canonicalizeAction(action);

    final resolvedRole =
        (role != null && actorRoleOptions.contains(role)) ? role : null;
    final resolvedCategory =
        (cat != null && categoryOptions.contains(cat)) ? cat : null;

    return {
      'page': page < 1 ? 1 : page,
      'limit': limit.clamp(1, 100),
      if (resolvedUserId != null && resolvedUserId.isNotEmpty)
        'userId': resolvedUserId,
      if (resolvedRole != null) 'actorRole': resolvedRole,
      if (resolvedCategory != null) 'category': resolvedCategory,
      if (act != null && act.isNotEmpty) 'action': act,
      if (from != null) 'from': _iso(from)!,
      if (to != null) 'to': _iso(to)!,
    };
  }

  /// Maps UI/legacy ban+unban codes to `USER_BAN`
  /// (`GET /user-history/admin/logs?action=USER_BAN`).
  static String? _canonicalizeAction(String? value) {
    final act = value?.trim().toUpperCase();
    if (act == null || act.isEmpty) return null;
    return switch (act) {
      'BAN' ||
      'BAN_USER' ||
      'UNBAN' ||
      'UNBAN_USER' ||
      'USER_UNBAN' =>
        'USER_BAN',
      _ => act,
    };
  }

  LogsQuery copyWith({
    int? page,
    int? limit,
    String? userId,
    UserEntity? user,
    String? actorRole,
    String? category,
    String? action,
    DateTime? from,
    DateTime? to,
    String? deviceId,
    bool clearUser = false,
    bool clearActorRole = false,
    bool clearCategory = false,
    bool clearAction = false,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearDeviceId = false,
  }) {
    return LogsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      userId: clearUser ? null : (userId ?? this.userId),
      user: clearUser ? null : (user ?? this.user),
      actorRole: clearActorRole ? null : (actorRole ?? this.actorRole),
      category: clearCategory ? null : (category ?? this.category),
      action: clearAction ? null : (action ?? this.action),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
    );
  }

  @override
  List<Object?> get props => [
        page,
        limit,
        userId,
        user,
        actorRole,
        category,
        action,
        from,
        to,
        deviceId,
      ];
}
