import '../../domain/entities/activity_post_summary_entity.dart';
import '../../domain/entities/activity_user_entity.dart';

class ActivityUserModel extends ActivityUserEntity {
  const ActivityUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
  });

  factory ActivityUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityUserModel(id: '', username: '');
    }
    return ActivityUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
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
