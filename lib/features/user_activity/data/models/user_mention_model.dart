import '../../domain/entities/user_mention_entity.dart';
import 'activity_summary_models.dart';

class UserMentionModel extends UserMentionEntity {
  const UserMentionModel({
    required super.id,
    required super.userId,
    super.postId,
    super.commentId,
    required super.createdAt,
    super.post,
    super.comment,
  });

  factory UserMentionModel.fromJson(Map<String, dynamic> json) {
    UserMentionCommentEntity? commentEntity;
    final rawComment = json['comment'];
    if (rawComment is Map<String, dynamic>) {
      final nestedPost = rawComment['post'];
      commentEntity = UserMentionCommentEntity(
        id: rawComment['id']?.toString() ?? '',
        content: rawComment['content']?.toString() ?? '',
        user: ActivityUserModel.fromJson(
          rawComment['user'] as Map<String, dynamic>?,
        ),
        post: ActivityPostSummaryModel.fromJson(
          nestedPost is Map<String, dynamic> ? nestedPost : null,
        ),
      );
    }

    return UserMentionModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      createdAt: _date(json['createdAt']),
      post: json['post'] is Map<String, dynamic>
          ? ActivityPostSummaryModel.fromJson(
              json['post'] as Map<String, dynamic>,
            )
          : null,
      comment: commentEntity,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
