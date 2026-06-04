import '../../domain/entities/user_comment_entity.dart';
import 'activity_summary_models.dart';

class UserCommentModel extends UserCommentEntity {
  const UserCommentModel({
    required super.id,
    required super.content,
    required super.postId,
    required super.userId,
    super.user,
    super.parentId,
    required super.likeCount,
    required super.replyCount,
    required super.isGift,
    super.giftId,
    required super.createdAt,
    required super.updatedAt,
    required super.post,
  });

  factory UserCommentModel.fromJson(Map<String, dynamic> json) {
    return UserCommentModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic>
          ? ActivityUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      parentId: json['parentId'] as String?,
      likeCount: _int(json['likeCount']) ?? 0,
      replyCount: _int(json['replyCount']) ?? 0,
      isGift: json['isGift'] as bool? ?? false,
      giftId: json['giftId'] as String?,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      post: ActivityPostSummaryModel.fromJson(
        json['post'] as Map<String, dynamic>?,
      ),
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
