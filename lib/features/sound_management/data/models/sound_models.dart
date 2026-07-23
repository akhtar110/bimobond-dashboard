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
    super.originalSoundId,
    super.creatorId,
    super.createdAt,
    super.creator,
  });

  factory SoundModel.fromJson(Map<String, dynamic> json) {
    final creatorJson = json['creator'];
    return SoundModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString(),
      duration: _asInt(json['duration']),
      useCount: _asInt(json['useCount']),
      isOriginal: json['isOriginal'] == true,
      isActive: json['isActive'] != false,
      originalSoundId: json['originalSoundId']?.toString(),
      creatorId: json['creatorId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      creator: creatorJson is Map<String, dynamic>
          ? SoundCreatorModel.fromJson(creatorJson)
          : null,
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
    return PaginatedSoundsModel(
      data: dataJson is List
          ? dataJson
              .whereType<Map<String, dynamic>>()
              .map(SoundModel.fromJson)
              .toList()
          : const [],
      meta: metaJson is Map<String, dynamic>
          ? PaginationMeta(
              total: SoundModel._asInt(metaJson['total']),
              page: SoundModel._asInt(metaJson['page']),
              limit: SoundModel._asInt(metaJson['limit']),
              totalPages: SoundModel._asInt(metaJson['totalPages']),
            )
          : const PaginationMeta(total: 0, page: 1, limit: 20, totalPages: 1),
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
