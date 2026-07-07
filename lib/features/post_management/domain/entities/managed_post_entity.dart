import '../../../categories/domain/entities/category_entity.dart';
import 'managed_post_sound_entity.dart';
import 'post_engagement_user_item.dart';
import 'post_media_entity.dart';

export '../../../categories/domain/entities/category_entity.dart';
export 'managed_post_sound_entity.dart';
export 'post_engagement_user_item.dart';
export 'post_media_entity.dart';

class ManagedPostEntity {
  const ManagedPostEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.userName,
    this.userFullName,
    this.userEmail,
    this.userProfileImage,
    this.userIsVerified = false,
    this.userFollowersCount = 0,
    this.userFollowingCount = 0,
    this.userPostsCount = 0,
    this.userJoinedAt,
    this.userIsBanned = false,
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
    this.repostCount = 0,
    this.recentReposts = const [],
    this.recentLikes = const [],
    this.recentViews = const [],
    this.recentMentions = const [],
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
    this.sound,
    this.originalPostId,
  });

  final String id;
  final String userId;
  final String type;

  // ── Author info ────────────────────────────────────────────────────────
  final String? userName;
  final String? userFullName;
  final String? userEmail;
  final String? userProfileImage;
  final bool userIsVerified;
  final int userFollowersCount;
  final int userFollowingCount;
  final int userPostsCount;
  final DateTime? userJoinedAt;
  final bool userIsBanned;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
  final String? animatedCoverUrl;

  /// Playable video URLs — excluded when picking a still preview image.
  Iterable<String> get playableMediaUrls sync* {
    final video = videoUrl?.trim();
    if (video != null && video.isNotEmpty) yield video;
    final hls = hlsUrl?.trim();
    if (hls != null && hls.isNotEmpty) yield hls;
    for (final item in media) {
      if (item.isVideo) {
        final url = item.url.trim();
        if (url.isNotEmpty) yield url;
      }
    }
  }

  /// First IMAGE from [media], otherwise [thumbnailUrl].
  String? get displayThumbnailUrl => resolvePostDisplayThumbnailUrl(
        media: media,
        thumbnailUrl: thumbnailUrl,
        excludeUrls: playableMediaUrls,
      );

  bool get isVideoPost => type.toUpperCase() == 'VIDEO';

  bool get containsVideoMedia =>
      isVideoPost || media.any((item) => item.isVideo);

  bool get hasAttachedSound =>
      soundId != null && soundId!.trim().isNotEmpty;

  String? get attachedSoundPlayUrl {
    final url = sound?.audioUrl;
    if (url != null && url.trim().isNotEmpty) return url.trim();
    return null;
  }

  bool get shouldPlayAttachedSound =>
      !containsVideoMedia &&
      hasAttachedSound &&
      attachedSoundPlayUrl != null;

  /// List/card preview image. For video posts, prefers [thumbnailUrl] (never a playable video URL).
  String? get previewThumbnailUrl {
    final exclude = playableMediaUrls;

    if (containsVideoMedia) {
      for (final candidate in [thumbnailUrl, animatedCoverUrl]) {
        if (isUsablePostThumbnailUrl(candidate, excludeUrls: exclude)) {
          return candidate!.trim();
        }
      }
      for (final item in media) {
        if (!item.isVideo &&
            isUsablePostThumbnailUrl(item.url, excludeUrls: exclude)) {
          return item.url;
        }
      }
      return null;
    }

    final resolved = displayThumbnailUrl;
    if (isUsablePostThumbnailUrl(resolved, excludeUrls: exclude)) {
      return resolved!.trim();
    }

    for (final candidate in [animatedCoverUrl, thumbnailUrl]) {
      if (isUsablePostThumbnailUrl(candidate, excludeUrls: exclude)) {
        return candidate!.trim();
      }
    }

    return null;
  }

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
  final int repostCount;
  final List<Map<String, dynamic>> recentReposts;
  final List<PostEngagementUserItem> recentLikes;
  final List<PostEngagementUserItem> recentViews;
  final List<PostEngagementUserItem> recentMentions;
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
  final ManagedPostSoundEntity? sound;
  final String? originalPostId;

  ManagedPostEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? userName,
    String? userFullName,
    String? userEmail,
    String? userProfileImage,
    bool? userIsVerified,
    int? userFollowersCount,
    int? userFollowingCount,
    int? userPostsCount,
    DateTime? userJoinedAt,
    bool? userIsBanned,
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
    int? repostCount,
    List<Map<String, dynamic>>? recentReposts,
    List<PostEngagementUserItem>? recentLikes,
    List<PostEngagementUserItem>? recentViews,
    List<PostEngagementUserItem>? recentMentions,
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
    ManagedPostSoundEntity? sound,
    String? originalPostId,
  }) {
    return ManagedPostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      userName: userName ?? this.userName,
      userFullName: userFullName ?? this.userFullName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      userIsVerified: userIsVerified ?? this.userIsVerified,
      userFollowersCount: userFollowersCount ?? this.userFollowersCount,
      userFollowingCount: userFollowingCount ?? this.userFollowingCount,
      userPostsCount: userPostsCount ?? this.userPostsCount,
      userJoinedAt: userJoinedAt ?? this.userJoinedAt,
      userIsBanned: userIsBanned ?? this.userIsBanned,
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
      repostCount: repostCount ?? this.repostCount,
      recentReposts: recentReposts ?? this.recentReposts,
      recentLikes: recentLikes ?? this.recentLikes,
      recentViews: recentViews ?? this.recentViews,
      recentMentions: recentMentions ?? this.recentMentions,
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
      sound: sound ?? this.sound,
      originalPostId: originalPostId ?? this.originalPostId,
    );
  }
}

class ManagedPostUpdateData {
  const ManagedPostUpdateData({
    this.description,
    this.category,
    this.categoryId,
    this.privacyStatus,
    this.status,
    this.allowComments,
    this.allowDuets,
    this.allowStitch,
  });

  final String? description;
  final String? category;
  final String? categoryId;
  final String? privacyStatus;
  final String? status;
  final bool? allowComments;
  final bool? allowDuets;
  final bool? allowStitch;
}
