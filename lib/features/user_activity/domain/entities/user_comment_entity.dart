import 'activity_post_summary_entity.dart';
import 'activity_user_entity.dart';

class UserCommentEntity {
  const UserCommentEntity({
    required this.id,
    required this.content,
    required this.postId,
    required this.userId,
    this.user,
    this.parentId,
    required this.likeCount,
    required this.replyCount,
    required this.isGift,
    this.giftId,
    required this.createdAt,
    required this.updatedAt,
    required this.post,
  });

  final String id;
  final String content;
  final String postId;
  final String userId;

  /// The user who wrote this comment (populated from the API `user` field).
  final ActivityUserEntity? user;

  final String? parentId;
  final int likeCount;
  final int replyCount;
  final bool isGift;
  final String? giftId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ActivityPostSummaryEntity post;
}
