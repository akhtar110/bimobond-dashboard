import 'package:flutter/foundation.dart';

@immutable
class ManagedPostSoundEntity {
  const ManagedPostSoundEntity({
    required this.id,
    this.name = '',
    this.author = '',
    this.audioUrl = '',
    this.duration,
  });

  final String id;
  final String name;
  final String author;
  final String audioUrl;
  final int? duration;

  bool get hasPlayableAudio => audioUrl.trim().isNotEmpty;

  ManagedPostSoundEntity copyWith({
    String? id,
    String? name,
    String? author,
    String? audioUrl,
    int? duration,
  }) {
    return ManagedPostSoundEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManagedPostSoundEntity &&
        other.id == id &&
        other.name == name &&
        other.author == author &&
        other.audioUrl == audioUrl &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(id, name, author, audioUrl, duration);
}
