import 'activity_post_summary_entity.dart';
import 'activity_user_entity.dart';

class UserMentionCommentEntity {
  const UserMentionCommentEntity({
    required this.id,
    required this.content,
    required this.user,
    required this.post,
  });

  final String id;
  final String content;
  final ActivityUserEntity user;
  final ActivityPostSummaryEntity post;
}

class UserMentionEntity {
  const UserMentionEntity({
    required this.id,
    required this.userId,
    this.postId,
    this.commentId,
    required this.createdAt,
    this.post,
    this.comment,
  });

  final String id;
  final String userId;
  final String? postId;
  final String? commentId;
  final DateTime createdAt;
  final ActivityPostSummaryEntity? post;
  final UserMentionCommentEntity? comment;

  bool get isCommentMention =>
      commentId != null && commentId!.isNotEmpty && comment != null;
}
