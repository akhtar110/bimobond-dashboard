import 'activity_user_entity.dart';

class ActivityPostSummaryEntity {
  const ActivityPostSummaryEntity({
    required this.id,
    this.userId,
    this.type,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.animatedCoverUrl,
    this.category,
    this.categoryId,
    this.media,
    this.user,
  });

  final String id;
  final String? userId;
  final String? type;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final String? animatedCoverUrl;
  final String? category;
  final String? categoryId;
  final List<Map<String, dynamic>>? media;
  final ActivityUserEntity? user;
}
