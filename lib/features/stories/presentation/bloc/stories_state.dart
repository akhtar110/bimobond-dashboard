import 'package:equatable/equatable.dart';

import '../../domain/entities/active_story_entity.dart';

abstract class StoriesState extends Equatable {
  const StoriesState();

  @override
  List<Object?> get props => [];
}

class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

class StoriesLoading extends StoriesState {
  const StoriesLoading();
}

class StoriesLoaded extends StoriesState {
  const StoriesLoaded({
    required this.stories,
    this.currentIndex = 0,
  });

  final List<ActiveStoryEntity> stories;
  final int currentIndex;

  StoriesLoaded copyWith({
    List<ActiveStoryEntity>? stories,
    int? currentIndex,
  }) {
    return StoriesLoaded(
      stories: stories ?? this.stories,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [stories, currentIndex];
}

class StoriesError extends StoriesState {
  const StoriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
