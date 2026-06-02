import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/managed_post_entity.dart';

/// Converts a [UserPostEntity] (from the user-detail posts list) to a
/// [ManagedPostEntity] so it can be opened in [PostManagementDetailScreen].
ManagedPostEntity managedPostFromUserPost(UserPostEntity post) {
  return ManagedPostEntity(
    id: post.id,
    userId: post.userId,
    type: post.type,
    videoUrl: post.videoUrl,
    hlsUrl: post.hlsUrl,
    thumbnailUrl: post.thumbnailUrl,
    media: PostMediaEntity.listFromJson(post.media),
    animatedCoverUrl: post.animatedCoverUrl,
    description: post.description,
    category: post.category,
    status: post.status,
    viewCount: post.viewCount,
    shareCount: post.shareCount,
    downloadCount: post.downloadCount,
    likeCount: post.likeCount,
    commentCount: post.commentCount,
    saveCount: post.saveCount,
    duration: post.duration,
    videoWidth: post.videoWidth,
    videoHeight: post.videoHeight,
    isAd: post.isAd,
    privacyStatus: post.privacyStatus,
    allowComments: post.allowComments,
    allowDuets: post.allowDuets,
    allowStitch: post.allowStitch,
    isStory: post.isStory,
    isAuctionable: post.isAuctionable,
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
    locationId: post.locationId,
    playlistId: post.playlistId,
    soundId: post.soundId,
    originalPostId: post.originalPostId,
  );
}
