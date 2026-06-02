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
    required super.status,
    required super.viewCount,
    required super.shareCount,
    required super.downloadCount,
    required super.likeCount,
    required super.commentCount,
    required super.saveCount,
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
    super.originalPostId,
    super.user,
    super.media,
    super.hashtags,
    super.sound,
    super.counts,
  });

  factory UserPostModel.fromJson(Map<String, dynamic> json) {
    return UserPostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'VIDEO',
      videoUrl: json['videoUrl'],
      hlsUrl: json['hlsUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      animatedCoverUrl: json['animatedCoverUrl'],
      description: json['description'],
      category: json['category'],
      status: json['status'] ?? 'PUBLISHED',
      viewCount: json['viewCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      downloadCount: json['downloadCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      saveCount: json['saveCount'] ?? 0,
      duration: json['duration'],
      videoWidth: json['videoWidth'],
      videoHeight: json['videoHeight'],
      isAd: json['isAd'] ?? false,
      privacyStatus: json['privacyStatus'] ?? 'PUBLIC',
      allowComments: json['allowComments'] ?? true,
      allowDuets: json['allowDuets'] ?? true,
      allowStitch: json['allowStitch'] ?? true,
      isStory: json['isStory'] ?? false,
      isAuctionable: json['isAuctionable'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      locationId: json['locationId'],
      playlistId: json['playlistId'],
      soundId: json['soundId'],
      originalPostId: json['originalPostId'],
      user: json['user'] as Map<String, dynamic>?,
      media: (json['media'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      hashtags: (json['hashtags'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      sound: json['sound'] as Map<String, dynamic>?,
      counts: json['_count'] as Map<String, dynamic>?,
    );
  }
}

class UserPostsResponseModel extends UserPostsResponseEntity {
  UserPostsResponseModel({
    required List<UserPostModel> data,
    required Map<String, dynamic> meta,
  }) : super(data: data, meta: meta);

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
    } else if (rawData is Map<String, dynamic> && rawData['meta'] is Map) {
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
