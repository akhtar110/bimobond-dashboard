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
    this.userId,
    this.author,
  });

  final String id;
  final String? description;
  final String? videoUrl;

  /// Post owner id when nested on the report payload.
  final String? userId;

  /// Nested post author profile when provided by the API.
  final ReportActorEntity? author;
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
  ///
  /// Post-linked reports take precedence — [reportedUserId] on a post report
  /// is the post author, not a standalone user report.
  String get targetType {
    if (commentId != null) return 'comment';
    if (postId != null || post?.id != null) return 'post';
    if (reportedUserId != null) return 'user';
    return 'unknown';
  }

  /// Post author id when the report targets a post (or comment on a post).
  String? get postAuthorUserId {
    final direct = reportedUserId ?? reportedUser?.id;
    if (direct != null && direct.isNotEmpty) return direct;
    final fromPost = post?.userId ?? post?.author?.id;
    if (fromPost != null && fromPost.isNotEmpty) return fromPost;
    return null;
  }

  /// Best available author profile for post-linked reports.
  ReportActorEntity? get postAuthor {
    if (reportedUser != null && reportedUser!.id.isNotEmpty) {
      return reportedUser;
    }
    if (post?.author != null && post!.author!.id.isNotEmpty) {
      return post!.author;
    }
    final id = postAuthorUserId;
    if (id == null || id.isEmpty) return null;
    return ReportActorEntity(id: id);
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
