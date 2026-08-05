import '../../../../core/utils/media_url_resolver.dart';

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
  final String? categoryId;
  final String status;
  final int viewCount;
  final int shareCount;
  final int downloadCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int repostCount;
  final int reportCount;
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
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? storyExpiresAt;
  final String? locationId;
  final String? playlistId;
  final String? soundId;
  final String? originalPostId;

  // Relations kept as raw maps to avoid cascading model changes.
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? media;
  final List<Map<String, dynamic>>? hashtags;
  final Map<String, dynamic>? sound;
  final Map<String, dynamic>? counts; // _count
  final List<Map<String, dynamic>>? recentReposts;

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
    this.categoryId,
    required this.status,
    required this.viewCount,
    required this.shareCount,
    required this.downloadCount,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    this.repostCount = 0,
    this.reportCount = 0,
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
    this.isLiked = false,
    this.isSaved = false,
    this.isReposted = false,
    required this.createdAt,
    required this.updatedAt,
    this.storyExpiresAt,
    this.locationId,
    this.playlistId,
    this.soundId,
    this.originalPostId,
    this.user,
    this.media,
    this.hashtags,
    this.sound,
    this.counts,
    this.recentReposts,
  });

  bool get hasAttachedSound =>
      (soundId != null && soundId!.trim().isNotEmpty) ||
      (sound != null && (sound!['audioUrl']?.toString().trim().isNotEmpty == true || sound!['url']?.toString().trim().isNotEmpty == true));

  String? get attachedSoundPlayUrl {
    final rawUrl = sound?['audioUrl']?.toString() ??
        sound?['url']?.toString() ??
        sound?['audio']?.toString() ??
        sound?['soundUrl']?.toString() ??
        sound?['path']?.toString();
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      return resolveMediaUrl(rawUrl.trim()) ?? rawUrl.trim();
    }
    return null;
  }

  bool get shouldPlayAttachedSound =>
      hasAttachedSound && attachedSoundPlayUrl != null;
}

class UserPostsResponseEntity {
  final List<UserPostEntity> data;
  final Map<String, dynamic> meta;

  const UserPostsResponseEntity({required this.data, required this.meta});
}
