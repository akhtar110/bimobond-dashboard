import 'package:equatable/equatable.dart';

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

class SoundOverviewEntity extends Equatable {
  const SoundOverviewEntity({
    required this.sounds,
    required this.usage,
    required this.topSounds,
  });

  final SoundStatsEntity sounds;
  final SoundUsageStatsEntity usage;
  final List<SoundEntity> topSounds;

  @override
  List<Object?> get props => [sounds, usage, topSounds];
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
    this.isActive = true,
  });

  final String name;
  final String author;
  final String audioUrl;
  final int duration;
  final String? coverUrl;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'author': author,
        'audioUrl': audioUrl,
        'duration': duration,
        if (coverUrl != null && coverUrl!.isNotEmpty) 'coverUrl': coverUrl,
        'isActive': isActive,
      };

  @override
  List<Object?> get props =>
      [name, author, audioUrl, duration, coverUrl, isActive];
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
    this.duration,
    this.isActive,
  });

  final String? name;
  final String? author;
  final int? duration;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (author != null) json['author'] = author;
    if (duration != null) json['duration'] = duration;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [name, author, duration, isActive];
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
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> soundIds;
  final List<String> notFoundIds;

  @override
  List<Object?> get props =>
      [action, successCount, notFoundCount, soundIds, notFoundIds];
}
