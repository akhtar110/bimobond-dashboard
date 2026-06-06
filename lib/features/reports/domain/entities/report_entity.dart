/// Slim nested objects carried inside [ReportEntity] — only the fields the
/// admin UI needs, matching the shapes returned by the Reports API.
class ReportActorEntity {
  const ReportActorEntity({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : (username ?? id);
}

class ReportPostEntity {
  const ReportPostEntity({
    required this.id,
    this.description,
    this.videoUrl,
  });

  final String id;
  final String? description;
  final String? videoUrl;
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportEntity {
  const ReportEntity({
    required this.id,
    this.reporterId,
    this.reportedUserId,
    this.postId,
    this.commentId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporter,
    this.reportedUser,
    this.post,
  });

  final String id;
  final String? reporterId;
  final String? reportedUserId;
  final String? postId;
  final String? commentId;
  final String reason;

  /// One of: `PENDING`, `RESOLVED`, `DISMISSED`.
  final String status;
  final DateTime createdAt;

  // Nested (populated by the API when the report is fetched)
  final ReportActorEntity? reporter;
  final ReportActorEntity? reportedUser;
  final ReportPostEntity? post;

  // ── Computed helpers ────────────────────────────────────────────────────────

  /// Which kind of content was reported: `post`, `user`, or `comment`.
  String get targetType {
    if (postId != null) return 'post';
    if (reportedUserId != null) return 'user';
    if (commentId != null) return 'comment';
    return 'unknown';
  }

  bool get isPending => status == 'PENDING';
  bool get isResolved => status == 'RESOLVED';
  bool get isDismissed => status == 'DISMISSED';

  ReportEntity copyWith({String? status}) => ReportEntity(
        id: id,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        postId: postId,
        commentId: commentId,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
        reporter: reporter,
        reportedUser: reportedUser,
        post: post,
      );
}
