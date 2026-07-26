import '../../../../core/utils/media_url_resolver.dart';
import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/sound_entities.dart';

class SoundCreatorModel extends SoundCreatorEntity {
  const SoundCreatorModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
  });

  factory SoundCreatorModel.fromJson(Map<String, dynamic> json) {
    return SoundCreatorModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class SoundRecentPostModel extends SoundRecentPostEntity {
  const SoundRecentPostModel({
    required super.id,
    super.caption,
    super.videoUrl,
    super.coverUrl,
    super.likeCount = 0,
    super.commentCount = 0,
    super.createdAt,
  });

  factory SoundRecentPostModel.fromJson(Map<String, dynamic> json) {
    return SoundRecentPostModel(
      id: json['id']?.toString() ?? '',
      caption: json['caption']?.toString() ?? json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? json['mediaUrl']?.toString(),
      coverUrl: json['coverUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
      likeCount: SoundModel._asInt(json['likeCount'] ?? json['likesCount']),
      commentCount: SoundModel._asInt(json['commentCount'] ?? json['commentsCount']),
      createdAt: SoundModel._parseDate(json['createdAt']),
    );
  }
}

class SoundModel extends SoundEntity {
  const SoundModel({
    required super.id,
    required super.name,
    required super.author,
    required super.audioUrl,
    super.coverUrl,
    required super.duration,
    required super.useCount,
    required super.isOriginal,
    required super.isActive,
    super.isFromDashboard = true,
    super.originalSoundId,
    super.creatorId,
    super.createdAt,
    super.creator,
    super.posts = const [],
  });

  factory SoundModel.fromJson(Map<String, dynamic> json) {
    final creatorJson = json['creator'];
    final postsJson = json['posts'];
    final isDash = json['isFromDashboard'];

    final rawAudio = json['audioUrl']?.toString() ??
        json['url']?.toString() ??
        json['fileUrl']?.toString() ??
        '';
    final rawCover = json['coverUrl']?.toString();
    return SoundModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      audioUrl: resolveMediaUrl(rawAudio) ?? rawAudio,
      coverUrl: resolveMediaUrl(rawCover) ?? rawCover,
      duration: _asInt(json['duration']),
      useCount: _asInt(json['useCount']),
      isOriginal: json['isOriginal'] == true,
      // Deactivate / Hidden must parse false reliably (bool, "false", 0).
      isActive: _readIsActive(json),
      isFromDashboard: isDash == true ||
          (isDash == null &&
              (json['creatorId'] == null ||
                  json['creatorId'].toString().isEmpty)),
      originalSoundId: json['originalSoundId']?.toString(),
      creatorId: json['creatorId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      creator: creatorJson is Map<String, dynamic>
          ? SoundCreatorModel.fromJson(creatorJson)
          : null,
      posts: postsJson is List
          ? postsJson
              .whereType<Map<String, dynamic>>()
              .map(SoundRecentPostModel.fromJson)
              .toList()
          : const [],
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Matches deactivate/hide semantics: `isActive: false` ⇒ Hidden.
  static bool _readIsActive(Map<String, dynamic> json) {
    if (json.containsKey('isActive')) {
      return _asBool(json['isActive'], defaultValue: true);
    }
    if (json.containsKey('active')) {
      return _asBool(json['active'], defaultValue: true);
    }
    final status = json['status']?.toString().trim().toUpperCase();
    if (status == null || status.isEmpty) return true;
    if (status == 'HIDDEN' ||
        status == 'INACTIVE' ||
        status == 'DEACTIVATED' ||
        status == 'DISABLED') {
      return false;
    }
    if (status == 'ACTIVE' || status == 'PUBLISHED') return true;
    return true;
  }

  static bool _asBool(Object? value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'active') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no' ||
        normalized == 'hidden' ||
        normalized == 'inactive' ||
        normalized == 'deactivated' ||
        normalized == 'disabled') {
      return false;
    }
    return defaultValue;
  }
}

class SoundOverviewModel extends SoundOverviewEntity {
  const SoundOverviewModel({
    required super.sounds,
    required super.usage,
    required super.segments,
    required super.topSounds,
  });

  factory SoundOverviewModel.fromJson(Map<String, dynamic> json) {
    final soundsJson = json['sounds'];
    final usageJson = json['usage'];
    final segmentsJson = json['segments'];
    final topJson = json['topSounds'];

    return SoundOverviewModel(
      sounds: soundsJson is Map<String, dynamic>
          ? SoundStatsModel.fromJson(soundsJson)
          : const SoundStatsModel(
              total: 0,
              active: 0,
              inactive: 0,
              originalUploads: 0,
            ),
      usage: usageJson is Map<String, dynamic>
          ? SoundUsageStatsModel.fromJson(usageJson)
          : const SoundUsageStatsModel(
              totalUseCount: 0,
              postsWithSoundLast24Hours: 0,
            ),
      segments: segmentsJson is Map<String, dynamic>
          ? SoundSegmentStatsModel.fromJson(segmentsJson)
          : const SoundSegmentStatsModel(total: 0),
      topSounds: topJson is List
          ? topJson
              .whereType<Map<String, dynamic>>()
              .map(SoundModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class SoundStatsModel extends SoundStatsEntity {
  const SoundStatsModel({
    required super.total,
    required super.active,
    required super.inactive,
    required super.originalUploads,
  });

  factory SoundStatsModel.fromJson(Map<String, dynamic> json) {
    return SoundStatsModel(
      total: SoundModel._asInt(json['total']),
      active: SoundModel._asInt(json['active']),
      inactive: SoundModel._asInt(json['inactive']),
      originalUploads: SoundModel._asInt(json['originalUploads']),
    );
  }
}

class SoundUsageStatsModel extends SoundUsageStatsEntity {
  const SoundUsageStatsModel({
    required super.totalUseCount,
    required super.postsWithSoundLast24Hours,
  });

  factory SoundUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return SoundUsageStatsModel(
      totalUseCount: SoundModel._asInt(json['totalUseCount']),
      postsWithSoundLast24Hours:
          SoundModel._asInt(json['postsWithSoundLast24Hours']),
    );
  }
}

class SoundSegmentStatsModel extends SoundSegmentStatsEntity {
  const SoundSegmentStatsModel({required super.total});

  factory SoundSegmentStatsModel.fromJson(Map<String, dynamic> json) {
    return SoundSegmentStatsModel(
      total: SoundModel._asInt(json['total']),
    );
  }
}

class PaginatedSoundsModel extends PaginatedSoundsEntity {
  const PaginatedSoundsModel({
    required super.data,
    required super.meta,
  });

  factory PaginatedSoundsModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    final metaJson = json['meta'];
    final sounds = <SoundEntity>[];
    if (dataJson is List) {
      for (final item in dataJson) {
        if (item is Map) {
          sounds.add(SoundModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final meta = metaJson is Map
        ? Map<String, dynamic>.from(metaJson)
        : const <String, dynamic>{};
    return PaginatedSoundsModel(
      data: sounds,
      meta: PaginationMeta(
        total: SoundModel._asInt(meta['total']),
        page: SoundModel._asInt(meta['page']) == 0
            ? 1
            : SoundModel._asInt(meta['page']),
        limit: SoundModel._asInt(meta['limit']) == 0
            ? 20
            : SoundModel._asInt(meta['limit']),
        totalPages: SoundModel._asInt(meta['totalPages']) == 0
            ? 1
            : SoundModel._asInt(meta['totalPages']),
      ),
    );
  }
}

class BulkSoundActionResultModel extends BulkSoundActionResultEntity {
  const BulkSoundActionResultModel({
    required super.action,
    required super.successCount,
    required super.notFoundCount,
    required super.soundIds,
    required super.notFoundIds,
    super.skippedCount,
    super.skippedIds,
  });

  factory BulkSoundActionResultModel.fromJson(Map<String, dynamic> json) {
    return BulkSoundActionResultModel(
      action: json['action']?.toString() ?? '',
      successCount: SoundModel._asInt(json['successCount']),
      notFoundCount: SoundModel._asInt(json['notFoundCount']),
      skippedCount: SoundModel._asInt(json['skippedCount']),
      soundIds: (json['soundIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notFoundIds: (json['notFoundIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skippedIds: (json['skippedIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
