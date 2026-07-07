import 'package:equatable/equatable.dart';

abstract class StoriesEvent extends Equatable {
  const StoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveStoriesEvent extends StoriesEvent {
  const LoadActiveStoriesEvent();
}

class RefreshActiveStoriesEvent extends StoriesEvent {
  const RefreshActiveStoriesEvent();
}

class OpenStoryEvent extends StoriesEvent {
  const OpenStoryEvent(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class StoryCompletedEvent extends StoriesEvent {
  const StoryCompletedEvent();
}
