import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/user_post_entity.dart';

class UserPostModel extends UserPostEntity {
  const UserPostModel({
    required super.id,
    required super.userId,
    required super.type,
    super.videoUrl,
    super.hlsUrl,
    super.thumbnailUrl,
    super.animatedCoverUrl,
    super.description,
    super.category,
    super.categoryId,
    required super.status,
    required super.viewCount,
    required super.shareCount,
    required super.downloadCount,
    required super.likeCount,
    required super.commentCount,
    required super.saveCount,
    super.repostCount,
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
    super.isLiked,
    super.isSaved,
    super.isReposted,
    required super.createdAt,
    required super.updatedAt,
    super.storyExpiresAt,
    super.locationId,
    super.playlistId,
    super.soundId,
    super.originalPostId,
    super.user,
    super.media,
    super.hashtags,
    super.sound,
    super.counts,
    super.recentReposts,
  });

  factory UserPostModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;

    String? parsedCategory;
    String? parsedCategoryId;
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      parsedCategory = rawCategory['name']?.toString();
      parsedCategoryId = rawCategory['id']?.toString();
    } else if (rawCategory is String && rawCategory.trim().isNotEmpty) {
      parsedCategory = rawCategory;
    }
    parsedCategoryId ??= json['categoryId']?.toString();

    return UserPostModel(
      id: json['id']?.toString() ?? '',
      userId:
          json['userId']?.toString() ?? userMap?['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'VIDEO',
      videoUrl: resolveMediaUrl(json['videoUrl'] as String?),
      hlsUrl: resolveMediaUrl(json['hlsUrl'] as String?),
      thumbnailUrl: resolveMediaUrl(json['thumbnailUrl'] as String?),
      animatedCoverUrl:
          resolveMediaUrl(json['animatedCoverUrl'] as String?),
      description: _readDescription(json),
      category: parsedCategory,
      categoryId: parsedCategoryId,
      status: json['status']?.toString() ?? 'PUBLISHED',
      viewCount: _int(json['viewCount']) ?? 0,
      shareCount: _int(json['shareCount']) ?? 0,
      downloadCount: _int(json['downloadCount']) ?? 0,
      likeCount: _int(json['likeCount']) ?? 0,
      commentCount: _int(json['commentCount']) ?? 0,
      saveCount: _int(json['saveCount']) ?? 0,
      repostCount: _int(json['repostCount']) ?? 0,
      duration: _int(json['duration']),
      videoWidth: _int(json['videoWidth']),
      videoHeight: _int(json['videoHeight']),
      isAd: json['isAd'] as bool? ?? false,
      privacyStatus:
          json['privacyStatus']?.toString() ?? 'PUBLIC',
      allowComments: json['allowComments'] as bool? ?? true,
      allowDuets: json['allowDuets'] as bool? ?? true,
      allowStitch: json['allowStitch'] as bool? ?? true,
      isStory: json['isStory'] as bool? ?? false,
      isAuctionable: json['isAuctionable'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      isReposted: json['isReposted'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      storyExpiresAt: _parseDate(json['storyExpiresAt']),
      locationId: json['locationId']?.toString(),
      playlistId: json['playlistId']?.toString(),
      soundId: json['soundId']?.toString(),
      originalPostId: json['originalPostId']?.toString(),
      user: userMap,
      media: (json['media'] as List?)?.map((e) {
        final item = e as Map<String, dynamic>;
        final rawUrl = item['url']?.toString() ?? '';
        return <String, dynamic>{
          ...item,
          'url': resolveMediaUrl(rawUrl) ?? rawUrl,
        };
      }).toList(),
      hashtags: (json['hashtags'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      sound: json['sound'] as Map<String, dynamic>?,
      counts: json['_count'] as Map<String, dynamic>?,
      recentReposts: (json['recentReposts'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class UserPostsResponseModel extends UserPostsResponseEntity {
  UserPostsResponseModel({
    required List<UserPostModel> super.data,
    required super.meta,
  });

  factory UserPostsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<dynamic> items;
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      items = rawData['data'] as List;
    } else {
      items = [];
    }

    final rawMeta = json['meta'];
    final Map<String, dynamic> meta;
    if (rawMeta is Map<String, dynamic>) {
      meta = rawMeta;
    } else if (rawData is Map<String, dynamic> &&
        rawData['meta'] is Map) {
      meta = Map<String, dynamic>.from(rawData['meta'] as Map);
    } else {
      meta = {};
    }

    return UserPostsResponseModel(
      data: items
          .map((e) => UserPostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: meta,
    );
  }
}

// ── helpers ─────────────────────────────────────────────────────────────────

String? _readDescription(Map<String, dynamic> json) {
  for (final key in ['description', 'caption']) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}
