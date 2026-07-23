import 'package:equatable/equatable.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../../promotions/domain/entities/pagination_meta.dart';

enum SoundSortMode {
  trending,
  recent,
  alphabetical;

  String get apiValue => switch (this) {
        SoundSortMode.trending => 'trending',
        SoundSortMode.recent => 'recent',
        SoundSortMode.alphabetical => 'name',
      };
}

enum SoundLibraryType {
  original,
  official,
  remix,
}

enum BulkSoundActionType {
  activate('ACTIVATE'),
  deactivate('DEACTIVATE'),
  delete('DELETE');

  const BulkSoundActionType(this.apiValue);
  final String apiValue;
}

class SoundCreatorEntity extends Equatable {
  const SoundCreatorEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl];
}

class SoundEntity extends Equatable {
  const SoundEntity({
    required this.id,
    required this.name,
    required this.author,
    required this.audioUrl,
    this.coverUrl,
    required this.duration,
    required this.useCount,
    required this.isOriginal,
    required this.isActive,
    this.originalSoundId,
    this.creatorId,
    this.createdAt,
    this.creator,
  });

  final String id;
  final String name;
  final String author;
  final String audioUrl;
  final String? coverUrl;
  final int duration;
  final int useCount;
  final bool isOriginal;
  final bool isActive;
  final String? originalSoundId;
  final String? creatorId;
  final DateTime? createdAt;
  final SoundCreatorEntity? creator;

  SoundLibraryType get libraryType {
    if (originalSoundId != null && originalSoundId!.isNotEmpty) {
      return SoundLibraryType.remix;
    }
    if (isOriginal || (creatorId != null && creatorId!.isNotEmpty)) {
      return SoundLibraryType.original;
    }
    return SoundLibraryType.official;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        author,
        audioUrl,
        coverUrl,
        duration,
        useCount,
        isOriginal,
        isActive,
        originalSoundId,
        creatorId,
        createdAt,
        creator,
      ];
}

class SoundStatsEntity extends Equatable {
  const SoundStatsEntity({
    required this.total,
    required this.active,
    required this.inactive,
    required this.originalUploads,
  });

  final int total;
  final int active;
  final int inactive;
  final int originalUploads;

  @override
  List<Object?> get props => [total, active, inactive, originalUploads];
}

class SoundUsageStatsEntity extends Equatable {
  const SoundUsageStatsEntity({
    required this.totalUseCount,
    required this.postsWithSoundLast24Hours,
  });

  final int totalUseCount;
  final int postsWithSoundLast24Hours;

  @override
  List<Object?> get props => [totalUseCount, postsWithSoundLast24Hours];
}

class SoundSegmentStatsEntity extends Equatable {
  const SoundSegmentStatsEntity({required this.total});

  final int total;

  @override
  List<Object?> get props => [total];
}

class SoundOverviewEntity extends Equatable {
  const SoundOverviewEntity({
    required this.sounds,
    required this.usage,
    required this.segments,
    required this.topSounds,
  });

  final SoundStatsEntity sounds;
  final SoundUsageStatsEntity usage;
  final SoundSegmentStatsEntity segments;
  final List<SoundEntity> topSounds;

  @override
  List<Object?> get props => [sounds, usage, segments, topSounds];
}

class SoundsQuery extends Equatable {
  const SoundsQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.sort = SoundSortMode.trending,
    this.isActive,
    this.creatorId,
  });

  final int page;
  final int limit;
  final String? search;
  final SoundSortMode sort;
  final bool? isActive;
  final String? creatorId;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort.apiValue,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (isActive != null) {
      params['isActive'] = isActive;
    }
    if (creatorId != null && creatorId!.trim().isNotEmpty) {
      params['creatorId'] = creatorId!.trim();
    }
    return params;
  }

  SoundsQuery copyWith({
    int? page,
    int? limit,
    String? search,
    bool clearSearch = false,
    SoundSortMode? sort,
    bool? isActive,
    bool clearIsActive = false,
    String? creatorId,
    bool clearCreatorId = false,
  }) {
    return SoundsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      sort: sort ?? this.sort,
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      creatorId: clearCreatorId ? null : (creatorId ?? this.creatorId),
    );
  }

  @override
  List<Object?> get props => [page, limit, search, sort, isActive, creatorId];
}

class PaginatedSoundsEntity extends Equatable {
  const PaginatedSoundsEntity({
    required this.data,
    required this.meta,
  });

  final List<SoundEntity> data;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}

class CreateSoundData extends Equatable {
  const CreateSoundData({
    required this.name,
    required this.author,
    required this.audioUrl,
    required this.duration,
    this.coverUrl,
    this.waveformPeaks,
    this.isActive = true,
  });

  final String name;
  final String author;
  final String audioUrl;
  final int duration;
  final String? coverUrl;
  final List<double>? waveformPeaks;
  final bool isActive;

  Map<String, dynamic> toJson() {
    final absoluteAudio =
        UpdateSoundData._absoluteHttpUrl(audioUrl) ?? audioUrl;
    final absoluteCover = UpdateSoundData._absoluteHttpUrl(coverUrl);
    return {
      'name': name,
      'author': author,
      'audioUrl': absoluteAudio,
      'duration': duration,
      if (absoluteCover != null) 'coverUrl': absoluteCover,
      if (waveformPeaks != null && waveformPeaks!.isNotEmpty)
        'waveformPeaks': waveformPeaks,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props =>
      [name, author, audioUrl, duration, coverUrl, waveformPeaks, isActive];
}

class UploadSoundData extends Equatable {
  const UploadSoundData({
    required this.bytes,
    required this.filename,
    required this.name,
    required this.author,
    required this.duration,
    this.coverBytes,
    this.coverFilename,
  });

  final List<int> bytes;
  final String filename;
  final String name;
  final String author;
  final int duration;
  final List<int>? coverBytes;
  final String? coverFilename;

  @override
  List<Object?> get props =>
      [bytes, filename, name, author, duration, coverBytes, coverFilename];
}

class UpdateSoundData extends Equatable {
  const UpdateSoundData({
    this.name,
    this.author,
    this.audioUrl,
    this.coverUrl,
    this.duration,
    this.waveformPeaks,
    this.isActive,
    this.clearCoverUrl = false,
    this.clearWaveformPeaks = false,
  });

  final String? name;
  final String? author;
  final String? audioUrl;
  final String? coverUrl;
  final int? duration;
  final List<double>? waveformPeaks;
  final bool? isActive;
  final bool clearCoverUrl;
  final bool clearWaveformPeaks;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (author != null) json['author'] = author;
    final absoluteAudio = _absoluteHttpUrl(audioUrl);
    if (absoluteAudio != null) json['audioUrl'] = absoluteAudio;
    if (clearCoverUrl) {
      // Omit coverUrl — Nest `@IsUrl()` rejects null/relative values.
      // Callers that need to clear should upload a replacement or use a
      // dedicated clear endpoint when available.
    } else {
      final absoluteCover = _absoluteHttpUrl(coverUrl);
      if (absoluteCover != null) json['coverUrl'] = absoluteCover;
    }
    if (duration != null) json['duration'] = duration;
    if (clearWaveformPeaks) {
      json['waveformPeaks'] = null;
    } else if (waveformPeaks != null) {
      json['waveformPeaks'] = waveformPeaks;
    }
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  /// Backend validators require a full `http(s)` URL, not `/uploads/...`.
  static String? _absoluteHttpUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final resolved = resolveMediaUrl(trimmed) ?? trimmed;
    final uri = Uri.tryParse(resolved);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return resolved;
  }

  @override
  List<Object?> get props => [
        name,
        author,
        audioUrl,
        coverUrl,
        duration,
        waveformPeaks,
        isActive,
        clearCoverUrl,
        clearWaveformPeaks,
      ];
}

class BulkSoundActionRequest extends Equatable {
  const BulkSoundActionRequest({
    required this.soundIds,
    required this.action,
  });

  final List<String> soundIds;
  final BulkSoundActionType action;

  Map<String, dynamic> toJson() => {
        'soundIds': soundIds,
        'action': action.apiValue,
      };

  @override
  List<Object?> get props => [soundIds, action];
}

class BulkSoundActionResultEntity extends Equatable {
  const BulkSoundActionResultEntity({
    required this.action,
    required this.successCount,
    required this.notFoundCount,
    required this.soundIds,
    required this.notFoundIds,
    this.skippedCount = 0,
    this.skippedIds = const [],
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> soundIds;
  final List<String> notFoundIds;
  final int skippedCount;
  final List<String> skippedIds;

  @override
  List<Object?> get props => [
        action,
        successCount,
        notFoundCount,
        soundIds,
        notFoundIds,
        skippedCount,
        skippedIds,
      ];
}
