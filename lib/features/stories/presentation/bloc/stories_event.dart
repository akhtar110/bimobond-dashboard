import 'package:equatable/equatable.dart';

import '../../domain/entities/story_entity.dart';

abstract class StoriesEvent extends Equatable {
  const StoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadStoriesEvent extends StoriesEvent {
  const LoadStoriesEvent();
}

class RefreshStoriesEvent extends StoriesEvent {
  const RefreshStoriesEvent();
}

class SearchStoriesEvent extends StoriesEvent {
  const SearchStoriesEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterStoriesEvent extends StoriesEvent {
  const FilterStoriesEvent({
    this.status,
    this.privacyStatus,
    this.activeOnly,
    this.userId,
    this.limit,
    this.clearStatus = false,
    this.clearPrivacyStatus = false,
    this.clearActiveOnly = false,
    this.clearUserId = false,
  });

  final String? status;
  final String? privacyStatus;
  final bool? activeOnly;
  final String? userId;
  final int? limit;
  final bool clearStatus;
  final bool clearPrivacyStatus;
  final bool clearActiveOnly;
  final bool clearUserId;

  @override
  List<Object?> get props => [
        status,
        privacyStatus,
        activeOnly,
        userId,
        limit,
        clearStatus,
        clearPrivacyStatus,
        clearActiveOnly,
        clearUserId,
      ];
}

class ChangePageEvent extends StoriesEvent {
  const ChangePageEvent(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class LoadMoreStoriesEvent extends StoriesEvent {
  const LoadMoreStoriesEvent();
}

class UpdateStoryEvent extends StoriesEvent {
  const UpdateStoryEvent(this.params);

  final UpdateStoryParams params;

  @override
  List<Object?> get props => [params];
}

class DeleteStoryEvent extends StoriesEvent {
  const DeleteStoryEvent(this.storyId);

  final String storyId;

  @override
  List<Object?> get props => [storyId];
}

class ChangeStoriesViewEvent extends StoriesEvent {
  const ChangeStoriesViewEvent(this.useGridView);

  final bool useGridView;

  @override
  List<Object?> get props => [useGridView];
}

class ClearStoriesFeedbackEvent extends StoriesEvent {
  const ClearStoriesFeedbackEvent();
}

class ClearStoriesFiltersEvent extends StoriesEvent {
  const ClearStoriesFiltersEvent();
}
