import '../../../../core/utils/media_url_resolver.dart';
import '../../../user_activity/data/models/activity_summary_models.dart';
import '../../../user_activity/domain/entities/activity_user_entity.dart';
import '../../../user_activity/data/models/user_like_model.dart';
import '../../../user_activity/data/models/user_mention_model.dart';
import '../../domain/entities/post_engagement_user_item.dart';

class PostEngagementUserModel extends PostEngagementUserItem {
  const PostEngagementUserModel({
    required super.id,
    required super.userId,
    super.username,
    super.fullName,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
    required super.createdAt,
    super.subtitle,
  });

  factory PostEngagementUserModel.fromJson(Map<String, dynamic> json) {
    final user = _userMap(json);
    final watched = _readInt(json['watchedDuration']);
    final mentionText = json['content']?.toString() ??
        json['mentionText']?.toString() ??
        json['text']?.toString();

    String? subtitle;
    if (watched != null && watched > 0) {
      subtitle = '${watched}s';
    } else if (mentionText != null && mentionText.trim().isNotEmpty) {
      subtitle = mentionText.trim();
    }

    return PostEngagementUserModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? user['name']?.toString(),
      fullName: user['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(
        user['avatarUrl'] as String? ??
            user['avatar'] as String? ??
            user['profileImage'] as String?,
      ),
      isVerified: user['isVerified'] as bool? ?? false,
      isBanned: user['isBanned'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']),
      subtitle: subtitle,
    );
  }

  factory PostEngagementUserModel.fromLikeJson(Map<String, dynamic> json) {
    final like = UserLikeModel.fromJson(json);
    return _fromActivityUser(
      id: like.id,
      userId: like.userId,
      user: like.user,
      createdAt: like.createdAt,
    );
  }

  factory PostEngagementUserModel.fromMentionJson(Map<String, dynamic> json) {
    final mention = UserMentionModel.fromJson(json);
    final userMap = _userMap(json, preferMentioned: true);
    final activityUser = userMap.isNotEmpty
        ? ActivityUserModel.fromJson(userMap)
        : (mention.comment?.user.id.isNotEmpty == true
            ? mention.comment!.user
            : mention.post?.user);

    String? subtitle;
    if (mention.isCommentMention && mention.comment != null) {
      subtitle = mention.comment!.content;
    } else {
      subtitle = mention.post?.description;
    }
    subtitle ??= json['content']?.toString() ?? json['mentionText']?.toString();

    if (activityUser != null && activityUser.id.isNotEmpty) {
      return _fromActivityUser(
        id: mention.id,
        userId: activityUser.id,
        user: activityUser,
        createdAt: mention.createdAt,
        subtitle: subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : null,
      );
    }

    return PostEngagementUserModel(
      id: mention.id,
      userId: mention.userId,
      createdAt: mention.createdAt,
      subtitle: subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : null,
    );
  }

  factory PostEngagementUserModel.fromRepostJson(Map<String, dynamic> json) {
    var user = _userMap(json);
    if (user.isEmpty &&
        (json.containsKey('username') ||
            json.containsKey('fullName') ||
            json.containsKey('avatarUrl'))) {
      user = json;
    }
    final quote = json['quote']?.toString() ?? json['caption']?.toString();
    return PostEngagementUserModel(
      id: json['id']?.toString() ??
          json['repostId']?.toString() ??
          user['id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? user['name']?.toString(),
      fullName: user['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(
        user['avatarUrl'] as String? ??
            user['avatar'] as String? ??
            user['profileImage'] as String?,
      ),
      isVerified: user['isVerified'] as bool? ?? false,
      isBanned: user['isBanned'] as bool? ?? false,
      createdAt: _readDate(
        json['createdAt'] ?? json['repostedAt'] ?? user['repostedAt'],
      ),
      subtitle: quote != null && quote.trim().isNotEmpty ? quote.trim() : null,
    );
  }

  static PostEngagementUserModel _fromActivityUser({
    required String id,
    required String userId,
    ActivityUserEntity? user,
    required DateTime createdAt,
    String? subtitle,
  }) {
    return PostEngagementUserModel(
      id: id,
      userId: user?.id.isNotEmpty == true ? user!.id : userId,
      username: user?.username,
      fullName: user?.fullName,
      avatarUrl: user?.avatarUrl,
      isVerified: user?.isVerified ?? false,
      isBanned: user?.isBanned ?? false,
      createdAt: createdAt,
      subtitle: subtitle,
    );
  }

  static Map<String, dynamic> _userMap(
    Map<String, dynamic> json, {
    bool preferMentioned = false,
  }) {
    final keys = preferMentioned
        ? ['mentionedUser', 'user', 'viewer', 'liker', 'repostedBy', 'reposter']
        : [
            'user',
            'repostedBy',
            'reposter',
            'mentionedUser',
            'viewer',
            'liker',
          ];
    for (final key in keys) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class PostEngagementUsersPageModel extends PostEngagementUsersPageEntity {
  const PostEngagementUsersPageModel({
    required super.items,
    required super.page,
    required super.hasMore,
  });

  factory PostEngagementUsersPageModel.fromMentionsJson(
    Map<String, dynamic> json, {
    required int limit,
  }) {
    return _build(
      json: json,
      limit: limit,
      listKeys: const ['mentions', 'recentMentions'],
      mapper: PostEngagementUserModel.fromMentionJson,
    );
  }

  factory PostEngagementUsersPageModel.fromLikesJson(
    Map<String, dynamic> json, {
    required int limit,
  }) {
    return _build(
      json: json,
      limit: limit,
      listKeys: const ['likes', 'recentLikes'],
      mapper: PostEngagementUserModel.fromLikeJson,
    );
  }

  factory PostEngagementUsersPageModel.fromViewsJson(
    Map<String, dynamic> json, {
    required int limit,
  }) {
    return _build(
      json: json,
      limit: limit,
      listKeys: const ['views', 'recentViews'],
      mapper: PostEngagementUserModel.fromJson,
    );
  }

  factory PostEngagementUsersPageModel.fromRepostsJson(
    Map<String, dynamic> json, {
    required int limit,
  }) {
    return _build(
      json: json,
      limit: limit,
      listKeys: const ['reposts', 'recentReposts', 'data', 'items'],
      mapper: PostEngagementUserModel.fromRepostJson,
    );
  }

  factory PostEngagementUsersPageModel.fromJson(
    Map<String, dynamic> json, {
    required int limit,
    required String listKey,
  }) {
    final recentKey = 'recent${listKey[0].toUpperCase()}${listKey.substring(1)}';
    return _build(
      json: json,
      limit: limit,
      listKeys: [listKey, recentKey],
      mapper: PostEngagementUserModel.fromJson,
    );
  }

  static PostEngagementUsersPageModel _build({
    required Map<String, dynamic> json,
    required int limit,
    required List<String> listKeys,
    required PostEngagementUserItem Function(Map<String, dynamic>) mapper,
  }) {
    final items = _extractItems(json, listKeys).map(mapper).toList();
    final meta = _extractMeta(json);
    final page = _readInt(meta['page']) ?? 1;
    final lastPage = _readInt(meta['lastPage']);
    final totalPages = _readInt(meta['totalPages']);

    final hasMore = lastPage != null
        ? page < lastPage
        : totalPages != null
            ? page < totalPages
            : items.length >= limit;

    return PostEngagementUsersPageModel(
      items: items,
      page: page,
      hasMore: hasMore,
    );
  }

  static Map<String, dynamic> _extractMeta(Map<String, dynamic> json) {
    final root = _unwrap(json);
    final meta = root['meta'];
    if (meta is Map<String, dynamic>) return meta;
    if (meta is Map) return Map<String, dynamic>.from(meta);
    return const {};
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return json;
  }

  static List<Map<String, dynamic>> _extractItems(
    Map<String, dynamic> json,
    List<String> listKeys,
  ) {
    if (json['data'] is List) {
      return _asMapList(json['data'] as List);
    }

    final unwrapped = _unwrap(json);
    if (unwrapped['data'] is List) {
      return _asMapList(unwrapped['data'] as List);
    }

    for (final key in listKeys) {
      final direct = json[key];
      if (direct is List) {
        return _asMapList(direct);
      }
      final nested = unwrapped[key];
      if (nested is List) {
        return _asMapList(nested);
      }
    }

    return const [];
  }

  static List<Map<String, dynamic>> _asMapList(List raw) {
    final mapped = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        mapped.add(entry);
      } else if (entry is Map) {
        mapped.add(Map<String, dynamic>.from(entry));
      }
    }
    return mapped;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

List<PostEngagementUserItem> parseEngagementUserList(
  dynamic raw, {
  PostEngagementKind? kind,
}) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((entry) {
    final map = entry is Map<String, dynamic>
        ? entry
        : Map<String, dynamic>.from(entry);
    if (kind == PostEngagementKind.reposts ||
        map.containsKey('repostedBy') ||
        map.containsKey('reposter') ||
        map.containsKey('repostId')) {
      return PostEngagementUserModel.fromRepostJson(map);
    }
    if (kind == PostEngagementKind.mentions ||
        map.containsKey('commentId') ||
        map.containsKey('mentionedUser') ||
        map['comment'] is Map) {
      return PostEngagementUserModel.fromMentionJson(map);
    }
    if (kind == PostEngagementKind.likes || map.containsKey('postId')) {
      return PostEngagementUserModel.fromLikeJson(map);
    }
    return PostEngagementUserModel.fromJson(map);
  }).toList();
}
