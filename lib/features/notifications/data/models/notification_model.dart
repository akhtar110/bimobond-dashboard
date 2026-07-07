import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationUserModel extends NotificationUserEntity {
  const NotificationUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    super.isVerified,
  });

  factory NotificationUserModel.fromJson(Map<String, dynamic> json) {
    return NotificationUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(json['avatarUrl']?.toString()),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.isRead,
    required super.createdAt,
    super.userId,
    super.actorId,
    super.postId,
    super.commentId,
    super.message,
    super.user,
    super.actor,
    super.post,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final actorJson = json['actor'] as Map<String, dynamic>?;
    final postJson = json['post'] as Map<String, dynamic>?;

    Map<String, dynamic>? resolvedPost;
    if (postJson != null) {
      resolvedPost = {
        ...postJson,
        if (postJson['thumbnailUrl'] != null)
          'thumbnailUrl':
              resolveMediaUrl(postJson['thumbnailUrl']?.toString()),
        if (postJson['videoUrl'] != null)
          'videoUrl': resolveMediaUrl(postJson['videoUrl']?.toString()),
      };
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      userId: json['userId']?.toString(),
      actorId: json['actorId']?.toString(),
      postId: json['postId']?.toString(),
      commentId: json['commentId']?.toString(),
      message: json['message']?.toString() ?? json['body']?.toString(),
      user: userJson != null ? NotificationUserModel.fromJson(userJson) : null,
      actor: actorJson != null
          ? NotificationUserModel.fromJson(actorJson)
          : null,
      post: resolvedPost,
    );
  }
}

/// Paginated response from `GET /notifications/admin/all`.
class NotificationFeedResponse {
  const NotificationFeedResponse({
    required this.notifications,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<NotificationEntity> notifications;
  final int page;
  final int lastPage;
  final int total;

  factory NotificationFeedResponse.fromJson(Map<String, dynamic> json) {
    // The API returns the list under "data" (same envelope as other endpoints).
    final rawList = json['data'] as List? ??
        json['notifications'] as List? ??
        [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationModel.fromJson(e))
        .toList();

    return NotificationFeedResponse(
      notifications: items,
      page: _int(meta['page']) ?? 1,
      // API returns "totalPages"; fall back to "lastPage" for other endpoints.
      lastPage: _int(meta['totalPages']) ?? _int(meta['lastPage']) ?? 1,
      total: _int(meta['total']) ?? items.length,
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
