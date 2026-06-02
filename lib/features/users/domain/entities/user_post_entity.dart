class UserPostEntity {
  final String id;
  final String userId;
  final String type; // VIDEO, IMAGE, CAROUSEL
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? animatedCoverUrl;
  final String? description;
  final String? category;
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
  
  // Relations (Keep as Map for simplicity or create entities if needed)
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? media;
  final List<Map<String, dynamic>>? hashtags;
  final Map<String, dynamic>? sound;
  final Map<String, dynamic>? counts; // _count

  const UserPostEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.videoUrl,
    this.hlsUrl,
    this.thumbnailUrl,
    this.animatedCoverUrl,
    this.description,
    this.category,
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
    this.user,
    this.media,
    this.hashtags,
    this.sound,
    this.counts,
  });
}

class UserPostsResponseEntity {
  final List<UserPostEntity> data;
  final Map<String, dynamic> meta;

  const UserPostsResponseEntity({required this.data, required this.meta});
}
