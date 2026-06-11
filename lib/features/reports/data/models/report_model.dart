import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/report_entity.dart';

class ReportActorModel extends ReportActorEntity {
  const ReportActorModel({
    required super.id,
    super.username,
    super.fullName,
    super.avatarUrl,
  });

  factory ReportActorModel.fromJson(Map<String, dynamic> json) =>
      ReportActorModel(
        id: json['id']?.toString() ?? '',
        username: json['username'] as String?,
        fullName: json['fullName'] as String?,
        avatarUrl: resolveMediaUrl(
          json['avatarUrl'] as String? ??
              json['avatar'] as String? ??
              json['profileImage'] as String?,
        ),
      );
}

class ReportPostModel extends ReportPostEntity {
  const ReportPostModel({
    required super.id,
    super.description,
    super.videoUrl,
    super.userId,
    super.author,
  });

  factory ReportPostModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final author = rawUser is Map<String, dynamic>
        ? ReportActorModel.fromJson(rawUser)
        : null;

    return ReportPostModel(
      id: json['id']?.toString() ?? '',
      description: json['description'] as String?,
      videoUrl: resolveMediaUrl(json['videoUrl'] as String?),
      userId: json['userId']?.toString() ?? author?.id,
      author: author,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    super.reporterId,
    super.reportedUserId,
    super.postId,
    super.commentId,
    required super.reason,
    required super.status,
    required super.createdAt,
    super.reporter,
    super.reportedUser,
    super.post,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final rawReporter = json['reporter'];
    final rawReportedUser = json['reportedUser'];
    final rawPost = json['post'];

    final parsedPost = rawPost is Map<String, dynamic>
        ? ReportPostModel.fromJson(rawPost)
        : null;
    final postAuthor = parsedPost?.author;
    final postAuthorId = parsedPost?.userId ?? postAuthor?.id;
    final hasPostTarget =
        json['postId'] != null || parsedPost != null || json['commentId'] != null;

    final reportedUserId = json['reportedUserId']?.toString() ??
        (rawReportedUser is Map<String, dynamic>
            ? rawReportedUser['id']?.toString()
            : null) ??
        (hasPostTarget ? postAuthorId : null);

    final reportedUser = rawReportedUser is Map<String, dynamic>
        ? ReportActorModel.fromJson(rawReportedUser)
        : (hasPostTarget ? postAuthor : null);

    return ReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporterId']?.toString() ??
          (rawReporter is Map<String, dynamic>
              ? rawReporter['id']?.toString()
              : null),
      reportedUserId: reportedUserId,
      postId: json['postId']?.toString() ?? parsedPost?.id,
      commentId: json['commentId']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: _parseDate(json['createdAt']),
      reporter: rawReporter is Map<String, dynamic>
          ? ReportActorModel.fromJson(rawReporter)
          : null,
      reportedUser: reportedUser,
      post: parsedPost,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
