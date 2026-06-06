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
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class ReportPostModel extends ReportPostEntity {
  const ReportPostModel({
    required super.id,
    super.description,
    super.videoUrl,
  });

  factory ReportPostModel.fromJson(Map<String, dynamic> json) =>
      ReportPostModel(
        id: json['id']?.toString() ?? '',
        description: json['description'] as String?,
        videoUrl: json['videoUrl'] as String?,
      );
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

    return ReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporterId']?.toString() ??
          (rawReporter is Map<String, dynamic>
              ? rawReporter['id']?.toString()
              : null),
      reportedUserId: json['reportedUserId']?.toString() ??
          (rawReportedUser is Map<String, dynamic>
              ? rawReportedUser['id']?.toString()
              : null),
      postId: json['postId']?.toString() ??
          (rawPost is Map<String, dynamic> ? rawPost['id']?.toString() : null),
      commentId: json['commentId']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: _parseDate(json['createdAt']),
      reporter: rawReporter is Map<String, dynamic>
          ? ReportActorModel.fromJson(rawReporter)
          : null,
      reportedUser: rawReportedUser is Map<String, dynamic>
          ? ReportActorModel.fromJson(rawReportedUser)
          : null,
      post: rawPost is Map<String, dynamic>
          ? ReportPostModel.fromJson(rawPost)
          : null,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
