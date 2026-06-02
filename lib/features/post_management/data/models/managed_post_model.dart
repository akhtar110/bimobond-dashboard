import '../../../categories/data/models/category_model.dart';
import '../../domain/entities/managed_post_entity.dart';

class ManagedPostModel extends ManagedPostEntity {
  const ManagedPostModel({
    required super.id,
    required super.userId,
    required super.type,
    super.userName,
    super.userProfileImage,
    super.videoUrl,
    super.hlsUrl,
    super.thumbnailUrl,
    super.media,
    super.animatedCoverUrl,
    super.description,
    super.category,
    super.categoryEntity,
    required super.status,
    required super.viewCount,
    required super.shareCount,
    required super.downloadCount,
    required super.likeCount,
    required super.commentCount,
    required super.saveCount,
    super.duration,
    super.videoWidth,
    super.videoHeight,
    required super.isAd,
    required super.privacyStatus,
    required super.allowComments,
    required super.allowDuets,
    required super.allowStitch,
    required super.isStory,
    required super.isAuctionable,
    required super.createdAt,
    required super.updatedAt,
    super.locationId,
    super.playlistId,
    super.soundId,
    super.originalPostId,
  });

  factory ManagedPostModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    // category can be a nested object or a plain string
    CategoryModel? parsedCategoryEntity;
    String? parsedCategory;
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      parsedCategoryEntity = CategoryModel.fromJson(rawCategory);
      parsedCategory = parsedCategoryEntity.name;
    } else if (rawCategory is String) {
      parsedCategory = rawCategory;
    }

    return ManagedPostModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'VIDEO',
      userName: user?['username'] as String? ??
          user?['name'] as String?,
      userProfileImage: user?['avatar'] as String? ??
          user?['profileImage'] as String? ??
          user?['profilePicture'] as String?,
      videoUrl: json['videoUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      media: PostMediaEntity.listFromJson(json['media']),
      animatedCoverUrl: json['animatedCoverUrl'] as String?,
      description: json['description'] as String?,
      category: parsedCategory,
      categoryEntity: parsedCategoryEntity,
      status: json['status']?.toString() ?? 'PUBLISHED',
      viewCount: _readInt(json['viewCount']) ?? 0,
      shareCount: _readInt(json['shareCount']) ?? 0,
      downloadCount: _readInt(json['downloadCount']) ?? 0,
      likeCount: _readInt(json['likeCount']) ?? 0,
      commentCount: _readInt(json['commentCount']) ?? 0,
      saveCount: _readInt(json['saveCount']) ?? 0,
      duration: _readInt(json['duration']),
      videoWidth: _readInt(json['videoWidth']),
      videoHeight: _readInt(json['videoHeight']),
      isAd: json['isAd'] as bool? ?? false,
      privacyStatus: json['privacyStatus']?.toString() ?? 'PUBLIC',
      allowComments: json['allowComments'] as bool? ?? true,
      allowDuets: json['allowDuets'] as bool? ?? true,
      allowStitch: json['allowStitch'] as bool? ?? true,
      isStory: json['isStory'] as bool? ?? false,
      isAuctionable: json['isAuctionable'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      locationId: json['locationId'] as String?,
      playlistId: json['playlistId'] as String?,
      soundId: json['soundId'] as String?,
      originalPostId: json['originalPostId'] as String?,
    );
  }

  static Map<String, dynamic> updatePayload(ManagedPostUpdateData data) {
    return {
      if (data.description != null) 'description': data.description,
      if (data.category != null) 'category': data.category,
      if (data.privacyStatus != null) 'privacyStatus': data.privacyStatus,
      if (data.status != null) 'status': data.status,
      if (data.allowComments != null) 'allowComments': data.allowComments,
      if (data.allowDuets != null) 'allowDuets': data.allowDuets,
      if (data.allowStitch != null) 'allowStitch': data.allowStitch,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
