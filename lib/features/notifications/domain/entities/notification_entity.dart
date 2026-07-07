/// Minimal user profile embedded in a notification.
class NotificationUserEntity {
  const NotificationUserEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : '@$username';
}

/// A single notification record returned by `GET /notifications/admin/all`.
class NotificationEntity {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.userId,
    this.actorId,
    this.postId,
    this.commentId,
    this.message,
    this.user,
    this.actor,
    this.post,
  });

  final String id;

  /// Raw type string from the API, e.g. `POST_LIKE`, `COMMENT`, `FOLLOW`, etc.
  final String type;
  final bool isRead;
  final DateTime createdAt;

  final String? userId;
  final String? actorId;
  final String? postId;
  final String? commentId;

  /// Optional human-readable message/body attached to the notification.
  final String? message;

  /// The user who received this notification.
  final NotificationUserEntity? user;

  /// The user who triggered this notification (e.g. who liked/commented).
  final NotificationUserEntity? actor;

  /// Minimal post snapshot (thumbnailUrl, description, id, etc.).
  final Map<String, dynamic>? post;
}
