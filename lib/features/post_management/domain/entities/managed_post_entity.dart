import '../../../categories/domain/entities/category_entity.dart';
import 'post_media_entity.dart';

export '../../../categories/domain/entities/category_entity.dart';
export 'post_media_entity.dart';

class ManagedPostEntity {
  const ManagedPostEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.userName,
    this.userProfileImage,
    this.videoUrl,
    this.hlsUrl,
    this.thumbnailUrl,
    this.media = const [],
    this.animatedCoverUrl,
    this.description,
    this.category,
    this.categoryEntity,
    required this.status,
    required this.viewCount,
    required this.shareCount,
    required this.downloadCount,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    this.duration,
    this.videoWidth,
    this.videoHeight,
    required this.isAd,
    required this.privacyStatus,
    required this.allowComments,
    required this.allowDuets,
    required this.allowStitch,
    required this.isStory,
    required this.isAuctionable,
    required this.createdAt,
    required this.updatedAt,
    this.locationId,
    this.playlistId,
    this.soundId,
    this.originalPostId,
  });

  final String id;
  final String userId;
  final String type;
  final String? userName;
  final String? userProfileImage;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
  final String? animatedCoverUrl;

  /// First IMAGE from [media], otherwise [thumbnailUrl].
  String? get displayThumbnailUrl => resolvePostDisplayThumbnailUrl(
        media: media,
        thumbnailUrl: thumbnailUrl,
      );
  final String? description;
  final String? category;
  final CategoryEntity? categoryEntity;
  final String status;
  final int viewCount;
  final int shareCount;
  final int downloadCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int? duration;
  final int? videoWidth;
  final int? videoHeight;
  final bool isAd;
  final String privacyStatus;
  final bool allowComments;
  final bool allowDuets;
  final bool allowStitch;
  final bool isStory;
  final bool isAuctionable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? locationId;
  final String? playlistId;
  final String? soundId;
  final String? originalPostId;

  ManagedPostEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? userName,
    String? userProfileImage,
    String? videoUrl,
    String? hlsUrl,
    String? thumbnailUrl,
    List<PostMediaEntity>? media,
    String? animatedCoverUrl,
    String? description,
    String? category,
    CategoryEntity? categoryEntity,
    String? status,
    int? viewCount,
    int? shareCount,
    int? downloadCount,
    int? likeCount,
    int? commentCount,
    int? saveCount,
    int? duration,
    int? videoWidth,
    int? videoHeight,
    bool? isAd,
    String? privacyStatus,
    bool? allowComments,
    bool? allowDuets,
    bool? allowStitch,
    bool? isStory,
    bool? isAuctionable,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? locationId,
    String? playlistId,
    String? soundId,
    String? originalPostId,
  }) {
    return ManagedPostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      media: media ?? this.media,
      animatedCoverUrl: animatedCoverUrl ?? this.animatedCoverUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryEntity: categoryEntity ?? this.categoryEntity,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      downloadCount: downloadCount ?? this.downloadCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      duration: duration ?? this.duration,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      isAd: isAd ?? this.isAd,
      privacyStatus: privacyStatus ?? this.privacyStatus,
      allowComments: allowComments ?? this.allowComments,
      allowDuets: allowDuets ?? this.allowDuets,
      allowStitch: allowStitch ?? this.allowStitch,
      isStory: isStory ?? this.isStory,
      isAuctionable: isAuctionable ?? this.isAuctionable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationId: locationId ?? this.locationId,
      playlistId: playlistId ?? this.playlistId,
      soundId: soundId ?? this.soundId,
      originalPostId: originalPostId ?? this.originalPostId,
    );
  }
}

class ManagedPostUpdateData {
  const ManagedPostUpdateData({
    this.description,
    this.category,
    this.privacyStatus,
    this.status,
    this.allowComments,
    this.allowDuets,
    this.allowStitch,
  });

  final String? description;
  final String? category;
  final String? privacyStatus;
  final String? status;
  final bool? allowComments;
  final bool? allowDuets;
  final bool? allowStitch;
}
