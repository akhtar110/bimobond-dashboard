import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/activity_post_summary_entity.dart';
import '../../domain/entities/activity_user_entity.dart';

class ActivityUserModel extends ActivityUserEntity {
  const ActivityUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    super.email,
    super.isVerified = false,
    super.followerCount = 0,
    super.followingCount = 0,
    super.postCount = 0,
    super.createdAt,
    super.isBanned = false,
  });

  factory ActivityUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityUserModel(id: '', username: '');
    }
    final counts = json['_count'] as Map<String, dynamic>?;

    return ActivityUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      avatarUrl: resolveMediaUrl(
        json['avatarUrl'] as String? ??
            json['avatar'] as String? ??
            json['profileImage'] as String?,
      ),
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      followerCount: _readInt(json['followerCount']) ??
          _readInt(counts?['followers']) ??
          _readInt(counts?['follower']) ??
          0,
      followingCount: _readInt(json['followingCount']) ??
          _readInt(counts?['following']) ??
          _readInt(counts?['followings']) ??
          0,
      postCount: _readInt(json['postCount']) ?? _readInt(counts?['posts']) ?? 0,
      createdAt: _readDate(json['createdAt']),
      isBanned: json['isBanned'] as bool? ?? false,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class ActivityPostSummaryModel extends ActivityPostSummaryEntity {
  const ActivityPostSummaryModel({
    required super.id,
    super.userId,
    super.type,
    super.description,
    super.thumbnailUrl,
    super.videoUrl,
    super.hlsUrl,
    super.animatedCoverUrl,
    super.category,
    super.categoryId,
    super.media,
    super.user,
  });

  factory ActivityPostSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityPostSummaryModel(id: '');
    }

    String? categoryName;
    String? categoryId;
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      categoryName = rawCategory['name']?.toString();
      categoryId = rawCategory['id']?.toString();
    } else if (rawCategory is String && rawCategory.isNotEmpty) {
      categoryName = rawCategory;
    }
    categoryId ??= json['categoryId']?.toString();
    categoryName ??= json['categoryName']?.toString();

    final thumbnailUrl = _readThumbnailUrl(json);
    final videoUrl = _readVideoUrl(json);
    final hlsUrl = resolveMediaUrl(json['hlsUrl'] as String?);
    final animatedCoverUrl = resolveMediaUrl(json['animatedCoverUrl'] as String?);

    var media = _parseMediaList(json['media']);
    media ??= buildSyntheticPostMediaMaps(
      videoUrl: videoUrl,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      animatedCoverUrl: animatedCoverUrl,
      type: json['type']?.toString(),
    );

    ActivityUserEntity? postUser;
    if (json['user'] is Map<String, dynamic>) {
      postUser = ActivityUserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['author'] is Map<String, dynamic>) {
      postUser =
          ActivityUserModel.fromJson(json['author'] as Map<String, dynamic>);
    }

    return ActivityPostSummaryModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? postUser?.id,
      type: json['type']?.toString(),
      description: _readDescription(json),
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      hlsUrl: hlsUrl,
      animatedCoverUrl: animatedCoverUrl,
      category: categoryName,
      categoryId: categoryId,
      media: media,
      user: postUser,
    );
  }

  static String? _readDescription(Map<String, dynamic> json) {
    for (final key in ['description', 'caption', 'content']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static List<Map<String, dynamic>>? _parseMediaList(dynamic rawMedia) {
    if (rawMedia is! List || rawMedia.isEmpty) return null;

    final items = rawMedia.whereType<Map>().map((entry) {
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

    return items.isEmpty ? null : items;
  }
}

/// Builds carousel entries when the API only returns legacy URL fields.
List<Map<String, dynamic>>? buildSyntheticPostMediaMaps({
  required String? videoUrl,
  required String? hlsUrl,
  required String? thumbnailUrl,
  required String? animatedCoverUrl,
  required String? type,
}) {
  final items = <Map<String, dynamic>>[];
  final playUrl = (videoUrl != null && videoUrl.isNotEmpty)
      ? videoUrl
      : ((hlsUrl != null && hlsUrl.isNotEmpty) ? hlsUrl : null);

  if (playUrl != null) {
    items.add({'url': playUrl, 'mediaType': 'VIDEO', 'order': 0});
  }

  final imageUrl = (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
      ? thumbnailUrl
      : ((animatedCoverUrl != null && animatedCoverUrl.isNotEmpty)
          ? animatedCoverUrl
          : null);

  if (imageUrl != null && !items.any((item) => item['url'] == imageUrl)) {
    items.add({
      'url': imageUrl,
      'mediaType': 'IMAGE',
      'order': items.isEmpty ? 0 : -1,
    });
  }

  if (items.isEmpty && imageUrl != null) {
    items.add({'url': imageUrl, 'mediaType': 'IMAGE', 'order': 0});
  }

  return items.isEmpty ? null : items;
}

String? _readVideoUrl(Map<String, dynamic> json) {
  final direct = resolveMediaUrl(json['videoUrl'] as String?);
  if (direct != null && direct.isNotEmpty) return direct;

  final video = json['video'];
  if (video is Map<String, dynamic>) {
    for (final key in ['url', 'videoUrl', 'src', 'path']) {
      final resolved = resolveMediaUrl(video[key] as String?);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
  }

  return resolveMediaUrl(json['mediaUrl'] as String?);
}

String? _readThumbnailUrl(Map<String, dynamic> json) {
  for (final key in [
    'thumbnailUrl',
    'thumbnail',
    'thumbUrl',
    'coverUrl',
    'posterUrl',
    'imageUrl',
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
