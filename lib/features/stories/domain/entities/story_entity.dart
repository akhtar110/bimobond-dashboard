import 'package:equatable/equatable.dart';

class StoryMediaEntity extends Equatable {
  const StoryMediaEntity({
    required this.url,
    this.id,
    this.type,
    this.thumbnailUrl,
    this.durationMs,
  });

  final String? id;
  final String url;
  final String? type;
  final String? thumbnailUrl;
  final int? durationMs;

  bool get isVideo {
    final normalized = type?.toUpperCase();
    if (normalized == 'VIDEO') return true;
    if (normalized == 'IMAGE') return false;
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('m3u8');
  }

  @override
  List<Object?> get props => [id, url, type, thumbnailUrl, durationMs];
}

class StoryUserEntity extends Equatable {
  const StoryUserEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.isPrivate = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final bool isPrivate;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final user = username.trim();
    if (user.isNotEmpty) return user;
    return id;
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, avatarUrl, isVerified, isPrivate];
}

class StorySoundSegmentEntity extends Equatable {
  const StorySoundSegmentEntity({
    this.id,
    this.title,
    this.audioUrl,
    this.coverUrl,
  });

  final String? id;
  final String? title;
  final String? audioUrl;
  final String? coverUrl;

  @override
  List<Object?> get props => [id, title, audioUrl, coverUrl];
}

class StoryEntity extends Equatable {
  const StoryEntity({
    required this.id,
    required this.userId,
    required this.description,
    required this.status,
    required this.privacyStatus,
    required this.ttlHours,
    required this.expiresAt,
    required this.viewCount,
    required this.isExpired,
    required this.media,
    this.hashtags = const [],
    this.location,
    this.soundSegment,
    this.user,
    this.allowReplies = true,
    this.allowSharing = true,
    this.allowReactions = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String description;
  final String status;
  final String privacyStatus;
  final int ttlHours;
  final DateTime expiresAt;
  final int viewCount;
  final bool isExpired;
  final List<StoryMediaEntity> media;
  final List<String> hashtags;
  final Map<String, dynamic>? location;
  final StorySoundSegmentEntity? soundSegment;
  final StoryUserEntity? user;
  final bool allowReplies;
  final bool allowSharing;
  final bool allowReactions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => !isExpired && status.toUpperCase() == 'PUBLISHED';

  StoryMediaEntity? get primaryMedia =>
      media.isNotEmpty ? media.first : null;

  bool get isVideo => primaryMedia?.isVideo ?? false;

  String? get previewUrl => primaryMedia?.url;

  String get thumbnailUrl {
    final mediaItem = primaryMedia;
    if (mediaItem == null) return '';
    if (mediaItem.isVideo) {
      return mediaItem.thumbnailUrl?.trim().isNotEmpty == true
          ? mediaItem.thumbnailUrl!.trim()
          : mediaItem.url;
    }
    return mediaItem.url;
  }

  String get caption => description.trim();

  @override
  List<Object?> get props => [
        id,
        userId,
        description,
        status,
        privacyStatus,
        ttlHours,
        expiresAt,
        viewCount,
        isExpired,
        media,
        hashtags,
        location,
        soundSegment,
        user,
        allowReplies,
        allowSharing,
        allowReactions,
        createdAt,
        updatedAt,
      ];
}

class PaginatedStoriesEntity extends Equatable {
  const PaginatedStoriesEntity({
    required this.stories,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<StoryEntity> stories;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasReachedMax => page >= totalPages;

  @override
  List<Object?> get props => [stories, total, page, limit, totalPages];
}

class StoryQuery extends Equatable {
  const StoryQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.privacyStatus,
    this.activeOnly,
    this.userId,
  });

  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? privacyStatus;
  final bool? activeOnly;
  final String? userId;

  StoryQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? privacyStatus,
    bool? activeOnly,
    String? userId,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearPrivacyStatus = false,
    bool clearActiveOnly = false,
    bool clearUserId = false,
  }) {
    return StoryQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      privacyStatus:
          clearPrivacyStatus ? null : (privacyStatus ?? this.privacyStatus),
      activeOnly: clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  List<Object?> get props =>
      [page, limit, search, status, privacyStatus, activeOnly, userId];
}

class UpdateStoryParams extends Equatable {
  const UpdateStoryParams({
    required this.id,
    this.description,
    this.privacyStatus,
    this.allowReplies,
    this.allowSharing,
    this.allowReactions,
    this.status,
    this.ttlHours,
  });

  final String id;
  final String? description;
  final String? privacyStatus;
  final bool? allowReplies;
  final bool? allowSharing;
  final bool? allowReactions;
  final String? status;
  final int? ttlHours;

  @override
  List<Object?> get props => [
        id,
        description,
        privacyStatus,
        allowReplies,
        allowSharing,
        allowReactions,
        status,
        ttlHours,
      ];
}
