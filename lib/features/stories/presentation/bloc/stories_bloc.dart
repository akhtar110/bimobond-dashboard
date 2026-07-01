import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_active_stories.dart';
import 'stories_event.dart';
import 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc({
    required GetActiveStories getActiveStories,
  })  : _getActiveStories = getActiveStories,
        super(const StoriesInitial()) {
    on<LoadActiveStoriesEvent>(_onLoad);
    on<RefreshActiveStoriesEvent>(_onRefresh);
    on<OpenStoryEvent>(_onOpenStory);
    on<StoryCompletedEvent>(_onStoryCompleted);
  }

  final GetActiveStories _getActiveStories;

  Future<void> _onLoad(
    LoadActiveStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    await _fetchStories(emit);
  }

  Future<void> _onRefresh(
    RefreshActiveStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final current = state;
    if (current is! StoriesLoaded) {
      emit(const StoriesLoading());
    }
    await _fetchStories(emit, preserveIndex: current is StoriesLoaded);
  }

  Future<void> _fetchStories(
    Emitter<StoriesState> emit, {
    bool preserveIndex = false,
  }) async {
    final previousIndex =
        preserveIndex && state is StoriesLoaded ? (state as StoriesLoaded).currentIndex : 0;

    final result = await _getActiveStories();

    result.fold(
      (failure) => emit(StoriesError(failure.message)),
      (stories) {
        if (stories.isEmpty) {
          emit(const StoriesLoaded(stories: [], currentIndex: 0));
          return;
        }

        final index = previousIndex.clamp(0, stories.length - 1);
        emit(StoriesLoaded(stories: stories, currentIndex: index));
      },
    );
  }

  void _onOpenStory(OpenStoryEvent event, Emitter<StoriesState> emit) {
    final current = state;
    if (current is! StoriesLoaded || current.stories.isEmpty) return;

    final index = event.index.clamp(0, current.stories.length - 1);
    if (index == current.currentIndex) return;
    emit(current.copyWith(currentIndex: index));
  }

  void _onStoryCompleted(StoryCompletedEvent event, Emitter<StoriesState> emit) {
    final current = state;
    if (current is! StoriesLoaded || current.stories.isEmpty) return;

    final nextIndex = current.currentIndex + 1;
    if (nextIndex >= current.stories.length) return;
    emit(current.copyWith(currentIndex: nextIndex));
  }
}
