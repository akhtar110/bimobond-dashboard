import 'activity_post_summary_entity.dart';
import 'activity_user_entity.dart';

class UserLikeEntity {
  const UserLikeEntity({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    required this.post,
    this.user,
  });

  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
  final ActivityPostSummaryEntity post;

  /// The user who gave this like (populated from the API `user` field).
  final ActivityUserEntity? user;
}
