import '../../../../core/utils/media_url_resolver.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../user_activity/domain/entities/activity_post_summary_entity.dart';
import '../../../user_activity/domain/entities/activity_user_entity.dart';
import '../../../user_activity/domain/entities/user_comment_entity.dart';
import '../../../user_activity/domain/entities/user_like_entity.dart';
import '../../../user_activity/domain/entities/user_mention_entity.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/managed_post_author_enrichment.dart';
import '../../domain/entities/managed_post_entity.dart';

ManagedPostAuthorSnapshot authorSnapshotFromActivityUser(
  ActivityUserEntity user,
) {
  return ManagedPostAuthorSnapshot(
    userId: user.id.isNotEmpty ? user.id : null,
    userName: user.username.isNotEmpty ? user.username : null,
    userFullName: user.fullName,
    userEmail: user.email,
    userProfileImage: user.avatarUrl != null
        ? resolveMediaUrl(user.avatarUrl)
        : null,
    userIsVerified: user.isVerified,
    userFollowersCount:
        user.followerCount > 0 ? user.followerCount : null,
    userFollowingCount:
        user.followingCount > 0 ? user.followingCount : null,
    userPostsCount: user.postCount > 0 ? user.postCount : null,
    userJoinedAt: user.createdAt,
    userIsBanned: user.isBanned,
  );
}

ManagedPostAuthorSnapshot authorSnapshotFromUserJson(
  Map<String, dynamic> json,
) {
  return ManagedPostAuthorSnapshot(
    userId: json['id']?.toString(),
    userName: json['username']?.toString() ?? json['name']?.toString(),
    userFullName: json['fullName'] as String?,
    userEmail: json['email'] as String?,
    userProfileImage: resolveMediaUrl(
      json['avatarUrl'] as String? ??
          json['avatar'] as String? ??
          json['profileImage'] as String?,
    ),
    userIsVerified: json['isVerified'] as bool?,
    userFollowersCount: _readInt(json['followerCount']),
    userFollowingCount: _readInt(json['followingCount']),
    userPostsCount: _readInt(json['postCount']),
    userJoinedAt: _readDate(json['createdAt']),
    userIsBanned: json['isBanned'] as bool?,
  );
}

/// Converts a [UserPostEntity] to [ManagedPostEntity] with author hydration.
ManagedPostEntity managedPostFromUserPost(
  UserPostEntity post, {
  UserEntity? author,
}) {
  final categoryEntity = _categoryEntityFromUserPost(post);

  var entity = ManagedPostEntity(
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
    categoryEntity: categoryEntity,
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

  if (post.user != null) {
    entity = enrichManagedPostAuthor(
      entity,
      snapshot: authorSnapshotFromUserJson(post.user!),
    );
  }

  if (author != null &&
      (entity.userId.isEmpty || entity.userId == author.id)) {
    entity = enrichManagedPostAuthor(entity, author: author);
  }

  if (entity.userId.isEmpty && author != null) {
    entity = entity.copyWith(userId: author.id);
  }

  return entity;
}

CategoryEntity? _categoryEntityFromUserPost(UserPostEntity post) {
  final categoryId = post.categoryId?.trim();
  if (categoryId == null || categoryId.isEmpty) return null;

  return CategoryModel(
    id: categoryId,
    name: post.category?.trim() ?? '',
    slug: '',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

ManagedPostEntity managedPostFromActivitySummary(
  ActivityPostSummaryEntity summary, {
  UserEntity? postOwner,
}) {
  if (summary.id.isEmpty) {
    return managedPostSeed('', author: postOwner);
  }

  final snapshot = summary.user != null && summary.user!.id.isNotEmpty
      ? authorSnapshotFromActivityUser(summary.user!)
      : null;

  final seed = managedPostSeed(
    summary.id,
    authorSnapshot: snapshot,
  );

  final withDescription = seed.description != null
      ? seed
      : seed.copyWith(description: summary.description);

  return enrichManagedPostAuthor(
    withDescription,
    snapshot: snapshot,
    author: postOwner != null &&
            (withDescription.userId.isEmpty ||
                withDescription.userId == postOwner.id)
        ? postOwner
        : null,
  );
}

ManagedPostEntity managedPostFromLike(
  UserLikeEntity like, {
  UserEntity? profileUser,
  required String type,
}) {
  final postOwner = type == 'received' ? profileUser : null;
  return managedPostFromActivitySummary(like.post, postOwner: postOwner);
}

ManagedPostEntity managedPostFromComment(
  UserCommentEntity comment, {
  UserEntity? profileUser,
  required String type,
}) {
  final postOwner = type == 'received' ? profileUser : null;
  return managedPostFromActivitySummary(comment.post, postOwner: postOwner);
}

ManagedPostEntity managedPostFromMention(UserMentionEntity mention) {
  final summary = mention.post ??
      (mention.comment != null
          ? mention.comment!.post
          : const ActivityPostSummaryEntity(id: ''));

  return managedPostFromActivitySummary(summary);
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _readDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
