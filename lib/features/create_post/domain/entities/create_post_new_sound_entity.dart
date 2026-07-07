import 'package:equatable/equatable.dart';

/// Inline sound object for `POST /posts` (`newSound` field).
class CreatePostNewSoundEntity extends Equatable {
  const CreatePostNewSoundEntity({
    required this.audioUrl,
    required this.duration,
    this.name,
    this.coverUrl,
    this.originalSoundId,
  });

  final String audioUrl;
  final int duration;
  final String? name;
  final String? coverUrl;
  final String? originalSoundId;

  bool get isComplete => audioUrl.trim().isNotEmpty && duration >= 1;

  Map<String, dynamic> toJson() {
    return {
      'audioUrl': audioUrl.trim(),
      'duration': duration,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (coverUrl != null && coverUrl!.trim().isNotEmpty)
        'coverUrl': coverUrl!.trim(),
      if (originalSoundId != null && originalSoundId!.trim().isNotEmpty)
        'originalSoundId': originalSoundId!.trim(),
    };
  }

  @override
  List<Object?> get props => [
        audioUrl,
        duration,
        name,
        coverUrl,
        originalSoundId,
      ];
}
