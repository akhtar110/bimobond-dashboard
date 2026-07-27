import '../../../../core/utils/media_url_resolver.dart';
import '../../../categories/data/models/category_model.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/utils/post_status_utils.dart';
import 'managed_post_sound_model.dart';
import 'post_engagement_user_model.dart';

class ManagedPostModel extends ManagedPostEntity {
  const ManagedPostModel({
    required super.id,
    required super.userId,
    required super.type,
    super.userName,
    super.userFullName,
    super.userEmail,
    super.userProfileImage,
    super.userIsVerified = false,
    super.userFollowersCount = 0,
    super.userFollowingCount = 0,
    super.userPostsCount = 0,
    super.userJoinedAt,
    super.userIsBanned = false,
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
    super.repostCount = 0,
    super.recentReposts = const [],
    super.recentLikes = const [],
    super.recentViews = const [],
    super.recentMentions = const [],
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
    super.sound,
    super.originalPostId,
  });

  factory ManagedPostModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final userCounts = user?['_count'] as Map<String, dynamic>?;

    // category can be a nested object, a plain string, or only categoryId.
    CategoryModel? parsedCategoryEntity;
    String? parsedCategory;
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      parsedCategoryEntity = CategoryModel.fromJson(rawCategory);
      parsedCategory = parsedCategoryEntity.name;
    } else if (rawCategory is String && rawCategory.isNotEmpty) {
      parsedCategory = rawCategory;
    } else {
      final categoryId = json['categoryId']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        parsedCategoryEntity = CategoryModel(
          id: categoryId,
          name: '',
          slug: '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    // Resolve user avatar — API field is "avatarUrl" (also accept legacy names).
    final rawAvatar = user?['avatarUrl'] as String? ??
        user?['avatar'] as String? ??
        user?['profileImage'] as String? ??
        user?['profilePicture'] as String?;

    return ManagedPostModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ??
          user?['id']?.toString() ??
          '',
      type: json['type']?.toString() ?? 'VIDEO',
      userName: user?['username'] as String? ?? user?['name'] as String?,
      userFullName: user?['fullName'] as String? ??
          user?['displayName'] as String? ??
          user?['name'] as String?,
      userEmail: user?['email'] as String?,
      userProfileImage: resolveMediaUrl(rawAvatar),
      userIsVerified: user?['isVerified'] as bool? ?? false,
      userFollowersCount: _readInt(user?['followerCount']) ??
          _readInt(userCounts?['followers']) ??
          _readInt(userCounts?['follower']) ??
          0,
      userFollowingCount: _readInt(user?['followingCount']) ??
          _readInt(userCounts?['following']) ??
          _readInt(userCounts?['followings']) ??
          0,
      userPostsCount:
          _readInt(user?['postCount']) ?? _readInt(userCounts?['posts']) ?? 0,
      userJoinedAt: user?['createdAt'] != null
          ? _readDate(user!['createdAt'])
          : null,
      userIsBanned: user?['isBanned'] as bool? ?? false,
      // Resolve all media URL fields from relative → absolute.
      videoUrl: resolveMediaUrl(json['videoUrl'] as String?),
      hlsUrl: resolveMediaUrl(json['hlsUrl'] as String?),
      thumbnailUrl: _readThumbnailUrl(json),
      // PostMediaEntity.fromJson already resolves each item's URL internally.
      media: PostMediaEntity.listFromJson(json['media']),
      animatedCoverUrl: resolveMediaUrl(json['animatedCoverUrl'] as String?),
      description: _readDescription(json),
      category: parsedCategory,
      categoryEntity: parsedCategoryEntity,
      status: normalizePostStatus(readPostStatusFromJson(json)),
      viewCount: _readInt(json['viewCount']) ?? 0,
      shareCount: _readInt(json['shareCount']) ?? 0,
      downloadCount: _readInt(json['downloadCount']) ?? 0,
      likeCount: _readInt(json['likeCount']) ?? 0,
      commentCount: _readInt(json['commentCount']) ?? 0,
      saveCount: _readInt(json['saveCount']) ?? 0,
      repostCount: _readInt(json['repostCount']) ??
          _readInt(json['repostsCount']) ??
          (json['reposts'] is List
              ? (json['reposts'] as List).length
              : _readInt(json['reposts'])) ??
          0,
      recentReposts: _parseRecentRepostMaps(json),
      recentLikes: parseEngagementUserList(
        json['recentLikes'] ?? json['likes'],
        kind: PostEngagementKind.likes,
      ),
      recentViews: parseEngagementUserList(
        json['recentViews'] ?? json['views'],
        kind: PostEngagementKind.views,
      ),
      recentMentions: parseEngagementUserList(
        json['recentMentions'] ?? json['mentions'],
        kind: PostEngagementKind.mentions,
      ),
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
      soundId: readManagedPostSoundId(json),
      sound: parseManagedPostSound(
        readManagedPostSoundRaw(json),
        soundId: readManagedPostSoundId(json),
      ),
      originalPostId: json['originalPostId'] as String?,
    );
  }

  static Map<String, dynamic> updatePayload(ManagedPostUpdateData data) {
    return {
      if (data.description != null) 'description': data.description,
      if (data.categoryId != null) 'categoryId': data.categoryId,
      if (data.privacyStatus != null) 'privacyStatus': data.privacyStatus,
      if (data.status != null) 'status': data.status,
      if (data.allowComments != null) 'allowComments': data.allowComments,
      if (data.allowDuets != null) 'allowDuets': data.allowDuets,
      if (data.allowStitch != null) 'allowStitch': data.allowStitch,
    };
  }

  static String? _readThumbnailUrl(Map<String, dynamic> json) {
    for (final key in [
      'thumbnailUrl',
      'thumbnail',
      'thumbUrl',
      'coverUrl',
      'posterUrl',
    ]) {
      final resolved = resolveMediaUrl(json[key] as String?);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }

    final video = json['video'];
    if (video is Map<String, dynamic>) {
      for (final key in ['thumbnailUrl', 'thumbnail', 'coverUrl']) {
        final resolved = resolveMediaUrl(video[key] as String?);
        if (resolved != null && resolved.isNotEmpty) return resolved;
      }
    }

    return null;
  }

  static String? _readDescription(Map<String, dynamic> json) {
    for (final key in ['description', 'caption']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _parseRecentRepostMaps(
    Map<String, dynamic> json,
  ) {
    for (final key in ['recentReposts', 'reposts', 'repostUsers']) {
      final raw = json[key];
      if (raw is! List || raw.isEmpty) continue;
      final mapped = <Map<String, dynamic>>[];
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          mapped.add(entry);
        } else if (entry is Map) {
          mapped.add(Map<String, dynamic>.from(entry));
        }
      }
      if (mapped.isNotEmpty) return mapped;
    }
    return const [];
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
