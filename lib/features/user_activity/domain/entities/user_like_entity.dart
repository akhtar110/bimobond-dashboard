import 'activity_post_summary_entity.dart';

class UserLikeEntity {
  const UserLikeEntity({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    required this.post,
  });

  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
  final ActivityPostSummaryEntity post;
}
