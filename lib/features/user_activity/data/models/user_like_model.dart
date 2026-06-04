import '../../domain/entities/user_like_entity.dart';
import 'activity_summary_models.dart';

class UserLikeModel extends UserLikeEntity {
  const UserLikeModel({
    required super.id,
    required super.userId,
    required super.postId,
    required super.createdAt,
    required super.post,
    super.user,
  });

  factory UserLikeModel.fromJson(Map<String, dynamic> json) {
    return UserLikeModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      createdAt: _date(json['createdAt']),
      post: ActivityPostSummaryModel.fromJson(
        json['post'] as Map<String, dynamic>?,
      ),
      user: json['user'] is Map<String, dynamic>
          ? ActivityUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
