import 'activity_post_summary_entity.dart';

class UserCommentEntity {
  const UserCommentEntity({
    required this.id,
    required this.content,
    required this.postId,
    required this.userId,
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
  final String? parentId;
  final int likeCount;
  final int replyCount;
  final bool isGift;
  final String? giftId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ActivityPostSummaryEntity post;
}
