import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/managed_post_sound_entity.dart';

ManagedPostSoundEntity? parseManagedPostSound(
  dynamic raw, {
  String? soundId,
}) {
  if (raw is! Map<String, dynamic>) {
    final id = soundId?.trim();
    if (id == null || id.isEmpty) return null;
    return ManagedPostSoundEntity(id: id);
  }

  final id = raw['id']?.toString().trim() ??
      soundId?.trim() ??
      '';
  if (id.isEmpty) return null;

  final audioUrl = resolveMediaUrl(
        raw['audioUrl']?.toString() ?? raw['url']?.toString(),
      ) ??
      raw['audioUrl']?.toString() ??
      raw['url']?.toString() ??
      '';

  return ManagedPostSoundEntity(
    id: id,
    name: raw['name']?.toString() ?? '',
    author: raw['author']?.toString() ?? '',
    audioUrl: audioUrl,
    duration: _readInt(raw['duration']),
  );
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
