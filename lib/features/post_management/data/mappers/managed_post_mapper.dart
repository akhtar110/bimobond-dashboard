import '../../../../core/utils/media_url_resolver.dart';
import '../../../user_activity/data/models/activity_summary_models.dart';
import '../../../user_activity/domain/entities/activity_post_summary_entity.dart';
import '../../../user_activity/domain/entities/activity_user_entity.dart';
import '../../../user_activity/domain/entities/user_activity_item_entity.dart';
import '../../../user_activity/domain/entities/user_comment_entity.dart';
import '../../../user_activity/domain/entities/user_like_entity.dart';
import '../../../user_activity/domain/entities/user_mention_entity.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../../users/data/models/user_post_model.dart';
import '../../../post_management/data/models/managed_post_model.dart';
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
    userFollowersCount: user.followerCount,
    userFollowingCount: user.followingCount,
    userPostsCount: user.postCount,
    userJoinedAt: user.createdAt,
    userIsBanned: user.isBanned,
  );
}

ManagedPostAuthorSnapshot authorSnapshotFromUserJson(
  Map<String, dynamic> json,
) {
  final counts = json['_count'] as Map<String, dynamic>?;

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
    userFollowersCount: _readInt(json['followerCount']) ??
        _readInt(counts?['followers']) ??
        _readInt(counts?['follower']),
    userFollowingCount: _readInt(json['followingCount']) ??
        _readInt(counts?['following']) ??
        _readInt(counts?['followings']),
    userPostsCount:
        _readInt(json['postCount']) ?? _readInt(counts?['posts']),
    userJoinedAt: _readDate(json['createdAt']),
    userIsBanned: json['isBanned'] as bool?,
  );
}

/// When [profileUser] owns the post, use them for author enrichment.
UserEntity? resolveProfileUserAsPostOwner(
  UserPostEntity post,
  UserEntity? profileUser,
) {
  if (profileUser == null || profileUser.id.isEmpty) return null;
  if (post.userId.isEmpty || post.userId == profileUser.id) return profileUser;
  return null;
}

Map<String, dynamic> userPostEntityToAdminJson(UserPostEntity post) {
  return {
    'id': post.id,
    'userId': post.userId,
    'type': post.type,
    if (post.videoUrl != null) 'videoUrl': post.videoUrl,
    if (post.hlsUrl != null) 'hlsUrl': post.hlsUrl,
    if (post.thumbnailUrl != null) 'thumbnailUrl': post.thumbnailUrl,
    if (post.animatedCoverUrl != null) 'animatedCoverUrl': post.animatedCoverUrl,
    if (post.description != null) 'description': post.description,
    if (post.categoryId != null) 'categoryId': post.categoryId,
    if (post.category != null) 'category': post.category,
    'status': post.status,
    'viewCount': post.viewCount,
    'shareCount': post.shareCount,
    'downloadCount': post.downloadCount,
    'likeCount': post.likeCount,
    'commentCount': post.commentCount,
    'saveCount': post.saveCount,
    'repostCount': post.repostCount,
    if (post.duration != null) 'duration': post.duration,
    if (post.videoWidth != null) 'videoWidth': post.videoWidth,
    if (post.videoHeight != null) 'videoHeight': post.videoHeight,
    'isAd': post.isAd,
    'privacyStatus': post.privacyStatus,
    'allowComments': post.allowComments,
    'allowDuets': post.allowDuets,
    'allowStitch': post.allowStitch,
    'isStory': post.isStory,
    'isAuctionable': post.isAuctionable,
    'createdAt': post.createdAt.toIso8601String(),
    'updatedAt': post.updatedAt.toIso8601String(),
    if (post.locationId != null) 'locationId': post.locationId,
    if (post.playlistId != null) 'playlistId': post.playlistId,
    if (post.soundId != null) 'soundId': post.soundId,
    if (post.sound != null) 'sound': post.sound,
    if (post.originalPostId != null) 'originalPostId': post.originalPostId,
    if (post.user != null) 'user': post.user,
    if (post.media != null && post.media!.isNotEmpty) 'media': post.media,
    if (post.recentReposts != null && post.recentReposts!.isNotEmpty)
      'recentReposts': post.recentReposts,
  };
}

Map<String, dynamic> activityPostSummaryToAdminJson(
  ActivityPostSummaryEntity summary,
) {
  return {
    'id': summary.id,
    if (summary.userId != null && summary.userId!.isNotEmpty)
      'userId': summary.userId,
    'type': summary.type ?? 'VIDEO',
    if (summary.videoUrl != null) 'videoUrl': summary.videoUrl,
    if (summary.hlsUrl != null) 'hlsUrl': summary.hlsUrl,
    if (summary.thumbnailUrl != null) 'thumbnailUrl': summary.thumbnailUrl,
    if (summary.animatedCoverUrl != null)
      'animatedCoverUrl': summary.animatedCoverUrl,
    if (summary.description != null) 'description': summary.description,
    if (summary.media != null && summary.media!.isNotEmpty) 'media': summary.media,
    if (summary.categoryId != null) 'categoryId': summary.categoryId,
    if (summary.category != null) 'category': summary.category,
    if (summary.user != null)
      'user': {
        'id': summary.user!.id,
        'username': summary.user!.username,
        if (summary.user!.fullName != null) 'fullName': summary.user!.fullName,
        if (summary.user!.avatarUrl != null) 'avatarUrl': summary.user!.avatarUrl,
        if (summary.user!.email != null) 'email': summary.user!.email,
        'isVerified': summary.user!.isVerified,
        'followerCount': summary.user!.followerCount,
        'followingCount': summary.user!.followingCount,
        'postCount': summary.user!.postCount,
        if (summary.user!.createdAt != null)
          'createdAt': summary.user!.createdAt!.toIso8601String(),
        'isBanned': summary.user!.isBanned,
      },
    'status': 'PUBLISHED',
  };
}

ManagedPostEntity mapAdminPostJsonToManagedPost(
  Map<String, dynamic> json, {
  UserEntity? postOwner,
}) {
  var entity = hydrateManagedPostMedia(ManagedPostModel.fromJson(json));

  final userMap = json['user'];
  if (userMap is Map<String, dynamic>) {
    entity = enrichManagedPostAuthor(
      entity,
      snapshot: authorSnapshotFromUserJson(userMap),
    );
  }

  if (postOwner != null &&
      (entity.userId.isEmpty || entity.userId == postOwner.id)) {
    entity = enrichManagedPostAuthor(entity, author: postOwner);
  }

  if (entity.userId.isEmpty && postOwner != null) {
    entity = entity.copyWith(userId: postOwner.id);
  }

  return entity;
}

/// Converts a [UserPostEntity] to [ManagedPostEntity] with author hydration.
ManagedPostEntity managedPostFromUserPost(
  UserPostEntity post, {
  UserEntity? author,
}) {
  final owner = resolveProfileUserAsPostOwner(post, author);
  return mapAdminPostJsonToManagedPost(
    userPostEntityToAdminJson(post),
    postOwner: owner,
  );
}

ManagedPostEntity managedPostFromActivitySummary(
  ActivityPostSummaryEntity summary, {
  UserEntity? postOwner,
}) {
  if (summary.id.isEmpty) {
    return managedPostSeed('', author: postOwner);
  }

  return mapAdminPostJsonToManagedPost(
    activityPostSummaryToAdminJson(summary),
    postOwner: postOwner,
  );
}

ActivityUserEntity? _activityUserFromMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return ActivityUserModel.fromJson(raw);
  }
  return null;
}

/// The user who performed the activity (commenter, liker, etc.).
ActivityUserEntity? activityActorFromActivityItem(
  UserActivityItemEntity item,
) {
  final details = item.details;
  for (final key in ['user', 'actor', 'commentUser', 'likeUser']) {
    final user = _activityUserFromMap(details[key]);
    if (user != null && user.id.isNotEmpty) return user;
  }

  final userId = item.detailString('userId');
  if (userId != null && userId.isNotEmpty) {
    return ActivityUserModel(
      id: userId,
      username: item.detailString('username') ??
          item.detailString('userUsername') ??
          '',
    );
  }
  return null;
}

ActivityUserEntity? postAuthorFromActivityDetails(
  Map<String, dynamic> details,
) {
  for (final key in ['postAuthor', 'postOwner', 'postUser', 'author']) {
    final user = _activityUserFromMap(details[key]);
    if (user != null && user.id.isNotEmpty) return user;
  }

  final nestedPost = details['post'] ?? details['targetPost'];
  if (nestedPost is Map<String, dynamic>) {
    for (final key in ['user', 'author']) {
      final fromPost = _activityUserFromMap(nestedPost[key]);
      if (fromPost != null && fromPost.id.isNotEmpty) return fromPost;
    }

    final nestedUserId = nestedPost['userId']?.toString();
    if (nestedUserId != null && nestedUserId.isNotEmpty) {
      return ActivityUserModel(
        id: nestedUserId,
        username: nestedPost['username']?.toString() ?? '',
      );
    }
  }

  final postUserId = details['postUserId']?.toString() ??
      details['postOwnerId']?.toString() ??
      details['authorId']?.toString();
  if (postUserId != null && postUserId.isNotEmpty) {
    final username = details['postUsername']?.toString() ??
        details['postOwnerUsername']?.toString() ??
        details['postOwnerName']?.toString();
    return ActivityUserModel(
      id: postUserId,
      username: username ?? '',
      fullName: details['postOwnerName']?.toString(),
    );
  }
  return null;
}

String? postOwnerDisplayNameFromActivityItem(UserActivityItemEntity item) {
  final author = postAuthorFromActivityDetails(item.details);
  if (author != null && author.displayName.isNotEmpty) {
    return author.displayName;
  }
  return item.detailString('postOwnerName');
}

ActivityPostSummaryEntity activityPostSummaryFromItem(
  UserActivityItemEntity item,
) {
  final nestedPost = item.details['post'] ?? item.details['targetPost'];
  if (nestedPost is Map<String, dynamic>) {
    return ActivityPostSummaryModel.fromJson(nestedPost);
  }

  final postAuthor = postAuthorFromActivityDetails(item.details);
  List<Map<String, dynamic>>? media;
  final rawMedia = item.details['media'] ?? item.details['postMedia'];
  if (rawMedia is List) {
    media = rawMedia.whereType<Map>().map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final rawUrl = map['url']?.toString() ??
          map['mediaUrl']?.toString() ??
          map['src']?.toString() ??
          '';
      if (rawUrl.isNotEmpty) {
        map['url'] = resolveMediaUrl(rawUrl) ?? rawUrl;
      }
      return map;
    }).where((item) => (item['url']?.toString() ?? '').isNotEmpty).toList();
    if (media.isEmpty) media = null;
  }

  final thumbnailUrl = resolveMediaUrl(
    item.detailString('thumbnailUrl') ?? item.detailString('postThumbnailUrl'),
  );
  final videoUrl = resolveMediaUrl(
    item.detailString('videoUrl') ?? item.detailString('postVideoUrl'),
  );
  final hlsUrl = resolveMediaUrl(item.detailString('hlsUrl'));
  final animatedCoverUrl = resolveMediaUrl(item.detailString('animatedCoverUrl'));
  final type = item.detailString('postType');

  media ??= buildSyntheticPostMediaMaps(
    videoUrl: videoUrl,
    hlsUrl: hlsUrl,
    thumbnailUrl: thumbnailUrl,
    animatedCoverUrl: animatedCoverUrl,
    type: type,
  );

  return ActivityPostSummaryEntity(
    id: item.detailString('postId') ?? '',
    userId: item.detailString('postUserId') ??
        item.detailString('postOwnerId') ??
        postAuthor?.id,
    type: type,
    description: item.detailString('postDescription') ??
        item.detailString('description'),
    thumbnailUrl: thumbnailUrl,
    videoUrl: videoUrl,
    hlsUrl: hlsUrl,
    animatedCoverUrl: animatedCoverUrl,
    category: item.detailString('category') ?? item.detailString('postCategory'),
    categoryId:
        item.detailString('categoryId') ?? item.detailString('postCategoryId'),
    media: media,
    user: postAuthor,
  );
}

UserEntity? resolveActivityItemPostOwner(
  UserActivityItemEntity item,
  UserEntity? profileUser,
  ActivityPostSummaryEntity summary,
) {
  if (profileUser == null) return null;

  final itemType = item.type.toUpperCase();
  if (itemType == 'CREATE_POST') return profileUser;

  final postAuthorId = summary.user?.id ??
      summary.userId ??
      postAuthorFromActivityDetails(item.details)?.id;

  if (postAuthorId != null &&
      postAuthorId.isNotEmpty &&
      postAuthorId == profileUser.id) {
    return profileUser;
  }
  return null;
}

ManagedPostEntity enrichManagedPostFromActivityItem(
  ManagedPostEntity entity,
  UserActivityItemEntity item,
  ActivityPostSummaryEntity summary,
  UserEntity? postOwner,
) {
  final postAuthor = postAuthorFromActivityDetails(item.details) ?? summary.user;
  final snapshot = postAuthor != null && postAuthor.id.isNotEmpty
      ? authorSnapshotFromActivityUser(postAuthor)
      : null;

  final postAuthorId = postAuthor?.id ??
      summary.userId ??
      summary.user?.id ??
      (entity.userId.isNotEmpty ? entity.userId : null);

  var enriched = enrichManagedPostAuthor(
    entity,
    snapshot: snapshot,
    author: postOwner != null &&
            postAuthorId != null &&
            postAuthorId == postOwner.id
        ? postOwner
        : null,
  );

  if (postAuthorId != null &&
      postAuthorId.isNotEmpty &&
      enriched.userId != postAuthorId) {
    enriched = enriched.copyWith(userId: postAuthorId);
  }

  return hydrateManagedPostMedia(
    normalizeManagedPostMediaFields(enriched),
  );
}

ManagedPostEntity managedPostFromActivityItem(
  UserActivityItemEntity item, {
  UserEntity? profileUser,
}) {
  final summary = activityPostSummaryFromItem(item);
  if (summary.id.isEmpty) {
    return managedPostSeed('', author: profileUser);
  }

  final postOwner = resolveActivityItemPostOwner(item, profileUser, summary);
  final nestedPost = item.details['post'] ?? item.details['targetPost'];
  final entity = nestedPost is Map<String, dynamic>
      ? managedPostFromUserPost(
          UserPostModel.fromJson(nestedPost),
          author: postOwner,
        )
      : managedPostFromActivitySummary(summary, postOwner: postOwner);

  return enrichManagedPostFromActivityItem(
    entity,
    item,
    summary,
    postOwner,
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

ManagedPostEntity managedPostFromMention(
  UserMentionEntity mention, {
  UserEntity? profileUser,
}) {
  final summary = mention.post ??
      (mention.comment != null
          ? mention.comment!.post
          : const ActivityPostSummaryEntity(id: ''));

  return managedPostFromActivitySummary(summary, postOwner: profileUser);
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
