import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/activity_post_summary_entity.dart';
import '../../domain/entities/activity_user_entity.dart';

class ActivityUserModel extends ActivityUserEntity {
  const ActivityUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    super.email,
    super.isVerified = false,
    super.followerCount = 0,
    super.followingCount = 0,
    super.postCount = 0,
    super.createdAt,
    super.isBanned = false,
  });

  factory ActivityUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityUserModel(id: '', username: '');
    }
    return ActivityUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      avatarUrl: resolveMediaUrl(
        json['avatarUrl'] as String? ??
            json['avatar'] as String? ??
            json['profileImage'] as String?,
      ),
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      followerCount: _readInt(json['followerCount']) ?? 0,
      followingCount: _readInt(json['followingCount']) ?? 0,
      postCount: _readInt(json['postCount']) ?? 0,
      createdAt: _readDate(json['createdAt']),
      isBanned: json['isBanned'] as bool? ?? false,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class ActivityPostSummaryModel extends ActivityPostSummaryEntity {
  const ActivityPostSummaryModel({
    required super.id,
    super.description,
    super.user,
  });

  factory ActivityPostSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityPostSummaryModel(id: '');
    }
    return ActivityPostSummaryModel(
      id: json['id']?.toString() ?? '',
      description: json['description'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? ActivityUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
