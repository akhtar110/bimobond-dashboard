import 'package:equatable/equatable.dart';

import 'story_entity.dart';

class StoryViewerAuthor extends Equatable {
  const StoryViewerAuthor({
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  final String name;
  final String username;
  final String? avatarUrl;

  @override
  List<Object?> get props => [name, username, avatarUrl];
}

/// Lightweight slide model for [StoryViewerDialog] without post dependencies.
class StoryViewerSlide extends Equatable {
  const StoryViewerSlide({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.author,
    this.mediaUrl,
    this.thumbnailUrl,
    this.isVideo = false,
    this.audioUrl,
  });

  final String id;
  final String description;
  final DateTime createdAt;
  final StoryViewerAuthor author;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final bool isVideo;
  final String? audioUrl;

  String get caption => description.trim();

  @override
  List<Object?> get props => [
        id,
        description,
        createdAt,
        author,
        mediaUrl,
        thumbnailUrl,
        isVideo,
        audioUrl,
      ];
}

extension StoryEntityViewer on StoryEntity {
  StoryViewerSlide toViewerSlide() {
    final storyUser = user;
    final author = StoryViewerAuthor(
      name: storyUser?.displayName ?? userId,
      username: storyUser?.username ?? '',
      avatarUrl: storyUser?.avatarUrl,
    );
    final created = createdAt ?? expiresAt.subtract(Duration(hours: ttlHours));

    return StoryViewerSlide(
      id: id,
      description: description,
      createdAt: created,
      author: author,
      mediaUrl: previewUrl,
      thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : previewUrl,
      isVideo: isVideo,
      audioUrl: soundSegment?.audioUrl,
    );
  }
}

extension StoryViewerSlideList on List<StoryEntity> {
  List<StoryViewerSlide> toViewerSlides() =>
      map((story) => story.toViewerSlide()).toList(growable: false);
}

String? storyProgressMediaUrl(StoryViewerSlide slide) {
  if (slide.isVideo) {
    final url = slide.mediaUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
  }
  final audio = slide.audioUrl?.trim();
  if (audio != null && audio.isNotEmpty) return audio;
  return null;
}
