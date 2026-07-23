import '../../domain/entities/story_entity.dart';

class StoryMediaModel extends StoryMediaEntity {
  const StoryMediaModel({
    required super.url,
    super.id,
    super.type,
    super.thumbnailUrl,
    super.durationMs,
  });

  factory StoryMediaModel.fromJson(Map<String, dynamic> json) {
    return StoryMediaModel(
      id: json['id']?.toString(),
      url: (json['url'] ?? json['mediaUrl'] ?? '').toString(),
      type: json['type']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      durationMs: _readInt(json['durationMs'] ?? json['duration']),
    );
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class StoryUserModel extends StoryUserEntity {
  const StoryUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    super.isVerified,
    super.isPrivate,
  });

  factory StoryUserModel.fromJson(Map<String, dynamic> json) {
    return StoryUserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] == true,
      isPrivate: json['isPrivate'] == true,
    );
  }
}

class StorySoundSegmentModel extends StorySoundSegmentEntity {
  const StorySoundSegmentModel({
    super.id,
    super.title,
    super.audioUrl,
    super.coverUrl,
  });

  factory StorySoundSegmentModel.fromJson(Map<String, dynamic> json) {
    return StorySoundSegmentModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString(),
      audioUrl: json['audioUrl']?.toString() ?? json['url']?.toString(),
      coverUrl: json['coverUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
    );
  }
}

class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.status,
    required super.privacyStatus,
    required super.ttlHours,
    required super.expiresAt,
    required super.viewCount,
    required super.isExpired,
    required super.media,
    super.hashtags,
    super.location,
    super.soundSegment,
    super.user,
    super.allowReplies,
    super.allowSharing,
    super.allowReactions,
    super.createdAt,
    super.updatedAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    final media = mediaRaw is List
        ? mediaRaw
            .whereType<Map<String, dynamic>>()
            .map(StoryMediaModel.fromJson)
            .where((item) => item.url.trim().isNotEmpty)
            .toList(growable: false)
        : const <StoryMediaModel>[];

    final hashtagsRaw = json['hashtags'];
    final hashtags = hashtagsRaw is List
        ? hashtagsRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    final userRaw = json['user'];
    final user = userRaw is Map<String, dynamic>
        ? StoryUserModel.fromJson(userRaw)
        : null;

    final soundRaw = json['soundSegment'];
    final sound = soundRaw is Map<String, dynamic>
        ? StorySoundSegmentModel.fromJson(soundRaw)
        : null;

    final locationRaw = json['location'];
    final location = locationRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(locationRaw)
        : null;

    return StoryModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? user?.id ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'PUBLISHED').toString(),
      privacyStatus: (json['privacyStatus'] ?? 'PUBLIC').toString(),
      ttlHours: _readInt(json['ttlHours']) ?? 24,
      expiresAt: _readDate(json['expiresAt']) ?? DateTime.now(),
      viewCount: _readInt(json['viewCount']) ?? 0,
      isExpired: json['isExpired'] == true,
      media: media,
      hashtags: hashtags,
      location: location,
      soundSegment: sound,
      user: user,
      allowReplies: json['allowReplies'] != false,
      allowSharing: json['allowSharing'] != false,
      allowReactions: json['allowReactions'] != false,
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  StoryEntity toEntity() => this;

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class PaginatedStoriesModel extends PaginatedStoriesEntity {
  const PaginatedStoriesModel({
    required super.stories,
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
  });

  factory PaginatedStoriesModel.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    final stories = dataRaw is List
        ? dataRaw
            .whereType<Map<String, dynamic>>()
            .map(StoryModel.fromJson)
            .toList(growable: false)
        : const <StoryModel>[];

    final meta = json['meta'];
    final metaMap = meta is Map<String, dynamic> ? meta : const {};

    final page = StoryModel._readInt(metaMap['page']) ?? 1;
    final limit = StoryModel._readInt(metaMap['limit']) ?? stories.length;
    final total = StoryModel._readInt(metaMap['total']) ?? stories.length;
    final totalPages = StoryModel._readInt(metaMap['totalPages']) ??
        (limit > 0 ? (total / limit).ceil() : 1);

    return PaginatedStoriesModel(
      stories: stories,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}

class UpdateStoryRequestModel {
  const UpdateStoryRequestModel({
    this.description,
    this.privacyStatus,
    this.allowReplies,
    this.allowSharing,
    this.allowReactions,
    this.status,
    this.ttlHours,
  });

  final String? description;
  final String? privacyStatus;
  final bool? allowReplies;
  final bool? allowSharing;
  final bool? allowReactions;
  final String? status;
  final int? ttlHours;

  factory UpdateStoryRequestModel.fromParams(UpdateStoryParams params) {
    return UpdateStoryRequestModel(
      description: params.description,
      privacyStatus: params.privacyStatus,
      allowReplies: params.allowReplies,
      allowSharing: params.allowSharing,
      allowReactions: params.allowReactions,
      status: params.status,
      ttlHours: params.ttlHours,
    );
  }

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (privacyStatus != null) body['privacyStatus'] = privacyStatus;
    if (allowReplies != null) body['allowReplies'] = allowReplies;
    if (allowSharing != null) body['allowSharing'] = allowSharing;
    if (allowReactions != null) body['allowReactions'] = allowReactions;
    if (status != null) body['status'] = status;
    if (ttlHours != null) body['ttlHours'] = ttlHours;
    return body;
  }
}
