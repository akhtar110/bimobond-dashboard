/// Immutable filter state for the admin notification feed.
class NotificationFilters {
  const NotificationFilters({
    this.type,
    this.isRead,
    this.userId,
  });

  /// Notification type filter, e.g. `POST_LIKE`, `FOLLOW`, `COMMENT`.
  final String? type;

  /// `true` → only read; `false` → only unread; `null` → both.
  final bool? isRead;

  /// Restrict to a specific recipient user.
  final String? userId;

  bool get isEmpty => type == null && isRead == null && userId == null;

  NotificationFilters copyWith({
    String? type,
    bool? isRead,
    String? userId,
    bool clearType = false,
    bool clearIsRead = false,
    bool clearUserId = false,
  }) {
    return NotificationFilters(
      type: clearType ? null : (type ?? this.type),
      isRead: clearIsRead ? null : (isRead ?? this.isRead),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  Map<String, dynamic> toQueryParams() => {
        if (type != null) 'type': type,
        if (isRead != null) 'isRead': isRead,
        if (userId != null) 'userId': userId,
      };

  @override
  bool operator ==(Object other) =>
      other is NotificationFilters &&
      other.type == type &&
      other.isRead == isRead &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(type, isRead, userId);
}
