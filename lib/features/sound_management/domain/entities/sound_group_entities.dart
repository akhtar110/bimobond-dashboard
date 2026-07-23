import 'package:equatable/equatable.dart';

import 'sound_entities.dart';

class SoundGroupMemberEntity extends Equatable {
  const SoundGroupMemberEntity({
    required this.sound,
    required this.sortOrder,
  });

  final SoundEntity sound;
  final int sortOrder;

  @override
  List<Object?> get props => [sound, sortOrder];
}

class SoundGroupEntity extends Equatable {
  const SoundGroupEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.soundCount,
    required this.sounds,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int soundCount;
  final List<SoundGroupMemberEntity> sounds;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        iconUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
        soundCount,
        sounds,
      ];
}

class CreateSoundGroupData extends Equatable {
  const CreateSoundGroupData({
    required this.name,
    required this.slug,
    this.iconUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug.trim().toLowerCase(),
        if (iconUrl != null && iconUrl!.trim().isNotEmpty)
          'iconUrl': iconUrl!.trim(),
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [name, slug, iconUrl, sortOrder, isActive];
}

class UpdateSoundGroupData extends Equatable {
  const UpdateSoundGroupData({
    this.name,
    this.slug,
    this.iconUrl,
    this.sortOrder,
    this.isActive,
    this.clearIconUrl = false,
  });

  final String? name;
  final String? slug;
  final String? iconUrl;
  final int? sortOrder;
  final bool? isActive;
  final bool clearIconUrl;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (slug != null) json['slug'] = slug!.trim().toLowerCase();
    if (clearIconUrl) {
      json['iconUrl'] = null;
    } else if (iconUrl != null) {
      json['iconUrl'] = iconUrl!.trim().isEmpty ? null : iconUrl!.trim();
    }
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props =>
      [name, slug, iconUrl, sortOrder, isActive, clearIconUrl];
}

class SoundGroupReorderItem extends Equatable {
  const SoundGroupReorderItem({required this.id, required this.sortOrder});

  final String id;
  final int sortOrder;

  Map<String, dynamic> toJson() => {'id': id, 'sortOrder': sortOrder};

  @override
  List<Object?> get props => [id, sortOrder];
}

class SoundGroupMembershipItem extends Equatable {
  const SoundGroupMembershipItem({
    required this.soundId,
    required this.sortOrder,
  });

  final String soundId;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'soundId': soundId,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [soundId, sortOrder];
}
