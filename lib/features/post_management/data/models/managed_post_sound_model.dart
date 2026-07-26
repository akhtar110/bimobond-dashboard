import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/managed_post_sound_entity.dart';

/// Parses post sound from API shapes:
/// - top-level `sound: { audioUrl, ... }`
/// - nested `soundSegment: { startMs, endMs, sound: { audioUrl, ... } }`
/// - inline `newSound: { audioUrl, ... }`
/// - bare sound / segment id string
ManagedPostSoundEntity? parseManagedPostSound(
  dynamic raw, {
  String? soundId,
}) {
  if (raw == null) {
    final id = soundId?.trim();
    if (id == null || id.isEmpty) return null;
    return ManagedPostSoundEntity(id: id);
  }

  if (raw is String) {
    final id = raw.trim().isNotEmpty ? raw.trim() : soundId?.trim();
    if (id == null || id.isEmpty) return null;
    return ManagedPostSoundEntity(id: id);
  }

  if (raw is! Map) {
    final id = soundId?.trim();
    if (id == null || id.isEmpty) return null;
    return ManagedPostSoundEntity(id: id);
  }

  final map = Map<String, dynamic>.from(raw);

  // Prefer nested track on soundSegment (authoritative playable source).
  final nestedSound = map['sound'];
  final track = nestedSound is Map
      ? Map<String, dynamic>.from(nestedSound)
      : map;

  final rawAudio = _pickAudioUrl(track) ?? _pickAudioUrl(map);
  final audioUrl = resolveMediaUrl(rawAudio) ?? rawAudio?.trim() ?? '';

  final id = track['id']?.toString().trim().isNotEmpty == true
      ? track['id'].toString().trim()
      : (soundId?.trim().isNotEmpty == true
          ? soundId!.trim()
          : (map['id']?.toString().trim().isNotEmpty == true
              ? map['id'].toString().trim()
              : audioUrl));

  if (id.isEmpty && audioUrl.isEmpty) return null;

  return ManagedPostSoundEntity(
    id: id,
    name: track['name']?.toString() ??
        track['title']?.toString() ??
        map['name']?.toString() ??
        map['title']?.toString() ??
        '',
    author: track['author']?.toString() ??
        track['artist']?.toString() ??
        map['author']?.toString() ??
        map['artist']?.toString() ??
        '',
    audioUrl: audioUrl,
    duration: _readInt(track['duration']) ?? _readInt(map['duration']),
  );
}

/// Resolves the playable sound UUID from a post JSON payload.
String? readManagedPostSoundId(Map<String, dynamic> json) {
  final direct = json['soundId']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  for (final key in ['sound', 'newSound']) {
    final raw = json[key];
    if (raw is Map) {
      final id = raw['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    } else if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
  }

  final segment = json['soundSegment'];
  if (segment is Map) {
    final nested = segment['sound'];
    if (nested is Map) {
      final id = nested['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    } else if (nested is String && nested.trim().isNotEmpty) {
      return nested.trim();
    }
  }

  return null;
}

/// Raw sound payload for [parseManagedPostSound], preferring nested track maps.
dynamic readManagedPostSoundRaw(Map<String, dynamic> json) {
  final sound = json['sound'];
  if (sound != null) return sound;

  final segment = json['soundSegment'];
  if (segment != null) return segment;

  return json['newSound'];
}

String? _pickAudioUrl(Map<String, dynamic> map) {
  for (final key in [
    'audioUrl',
    'url',
    'audio',
    'soundUrl',
    'fileUrl',
    'mediaUrl',
    'path',
  ]) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
