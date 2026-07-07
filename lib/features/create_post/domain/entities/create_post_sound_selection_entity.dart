import 'package:equatable/equatable.dart';

/// UI/preview metadata for the chosen sound (not sent when [soundId] is set).
class CreatePostSoundSelectionEntity extends Equatable {
  const CreatePostSoundSelectionEntity({
    required this.id,
    required this.name,
    required this.author,
    required this.audioUrl,
    required this.duration,
    this.coverUrl,
  });

  final String id;
  final String name;
  final String author;
  final String audioUrl;
  final int duration;
  final String? coverUrl;

  @override
  List<Object?> get props => [
        id,
        name,
        author,
        audioUrl,
        duration,
        coverUrl,
      ];
}
