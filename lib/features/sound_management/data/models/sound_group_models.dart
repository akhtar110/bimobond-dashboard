import '../../domain/entities/sound_group_entities.dart';
import 'sound_models.dart';

int _groupAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _groupParseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class SoundGroupMemberModel extends SoundGroupMemberEntity {
  const SoundGroupMemberModel({
    required super.sound,
    required super.sortOrder,
  });

  factory SoundGroupMemberModel.fromJson(Map<String, dynamic> json) {
    final sortOrder = _groupAsInt(json['sortOrder']);
    return SoundGroupMemberModel(
      sound: SoundModel.fromJson(json),
      sortOrder: sortOrder,
    );
  }
}

class SoundGroupModel extends SoundGroupEntity {
  const SoundGroupModel({
    required super.id,
    required super.name,
    required super.slug,
    super.iconUrl,
    required super.sortOrder,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
    required super.soundCount,
    required super.sounds,
  });

  factory SoundGroupModel.fromJson(Map<String, dynamic> json) {
    final soundsRaw = json['sounds'];
    final members = soundsRaw is List
        ? soundsRaw
            .whereType<Map<String, dynamic>>()
            .map(SoundGroupMemberModel.fromJson)
            .toList()
        : const <SoundGroupMemberModel>[];

    return SoundGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      sortOrder: _groupAsInt(json['sortOrder']),
      isActive: json['isActive'] != false,
      createdAt: _groupParseDate(json['createdAt']),
      updatedAt: _groupParseDate(json['updatedAt']),
      soundCount: _groupAsInt(json['soundCount'] ?? members.length),
      sounds: members,
    );
  }
}

List<SoundGroupEntity> parseSoundGroupList(Object? data) {
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(SoundGroupModel.fromJson)
        .toList();
  }
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is List) {
      return nested
          .whereType<Map<String, dynamic>>()
          .map(SoundGroupModel.fromJson)
          .toList();
    }
  }
  return const [];
}

SoundGroupEntity parseSoundGroup(Object? data) {
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return SoundGroupModel.fromJson(nested);
    }
    return SoundGroupModel.fromJson(data);
  }
  throw Exception('Invalid sound group response');
}
