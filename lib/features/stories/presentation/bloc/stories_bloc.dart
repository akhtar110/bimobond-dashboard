import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/story_entity.dart';
import '../../domain/usecases/delete_story.dart';
import '../../domain/usecases/get_stories.dart';
import '../../domain/usecases/update_story.dart';
import 'stories_event.dart';
import 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc({
    required GetStoriesUseCase getStoriesUseCase,
    required UpdateStoryUseCase updateStoryUseCase,
    required DeleteStoryUseCase deleteStoryUseCase,
  })  : _getStories = getStoriesUseCase,
        _updateStory = updateStoryUseCase,
        _deleteStory = deleteStoryUseCase,
        super(StoriesInitial()) {
    on<LoadStoriesEvent>(_onLoad);
    on<RefreshStoriesEvent>(_onRefresh);
    on<SearchStoriesEvent>(_onSearch);
    on<FilterStoriesEvent>(_onFilter);
    on<ChangePageEvent>(_onChangePage);
    on<LoadMoreStoriesEvent>(_onLoadMore);
    on<UpdateStoryEvent>(_onUpdate);
    on<DeleteStoryEvent>(_onDelete);
    on<ChangeStoriesViewEvent>(_onChangeView);
    on<ClearStoriesFeedbackEvent>(_onClearFeedback);
    on<ClearStoriesFiltersEvent>(_onClearFilters);
  }

  final GetStoriesUseCase _getStories;
  final UpdateStoryUseCase _updateStory;
  final DeleteStoryUseCase _deleteStory;

  static const defaultPageLimit = 20;

  int _loadRequestId = 0;
  bool _loadMoreBusy = false;
  bool _goToPageBusy = false;

  String? _searchQuery;
  String? _selectedStatus;
  String? _selectedPrivacyStatus;
  bool? _activeOnly;
  String? _userId;
  int _limit = defaultPageLimit;
  bool _useGridView = true;

  StoryQuery get _query => StoryQuery(
        page: 1,
        limit: _limit,
        search: _searchQuery,
        status: _selectedStatus,
        privacyStatus: _selectedPrivacyStatus,
        activeOnly: _activeOnly,
        userId: _userId,
      );

  Future<void> _onLoad(
    LoadStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    await _loadPage(emit, page: 1);
  }

  Future<void> _onRefresh(
    RefreshStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final current = state;
    final page = current is StoriesLoaded ? current.currentPage : 1;
    if (current is StoriesLoaded) {
      emit(current.copyWith(isRefreshing: true, clearFeedback: true));
    }
    await _loadPage(emit, page: page, preserveLoadedShell: true);
  }

  Future<void> _onSearch(
    SearchStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final trimmed = event.query.trim();
    _searchQuery = trimmed.isEmpty ? null : trimmed;
    await _loadPage(emit, page: 1);
  }

  Future<void> _onFilter(
    FilterStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    if (event.clearStatus) {
      _selectedStatus = null;
    } else if (event.status != null) {
      _selectedStatus = event.status;
    }

    if (event.clearPrivacyStatus) {
      _selectedPrivacyStatus = null;
    } else if (event.privacyStatus != null) {
      _selectedPrivacyStatus = event.privacyStatus;
    }

    if (event.clearActiveOnly) {
      _activeOnly = null;
    } else if (event.activeOnly != null) {
      _activeOnly = event.activeOnly;
    }

    if (event.clearUserId) {
      _userId = null;
    } else if (event.userId != null) {
      final trimmed = event.userId!.trim();
      _userId = trimmed.isEmpty ? null : trimmed;
    }

    if (event.limit != null && event.limit! > 0) {
      _limit = event.limit!;
    }

    await _loadPage(emit, page: 1);
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<StoriesState> emit,
  ) async {
    if (_goToPageBusy) return;
    _goToPageBusy = true;
    try {
      await _loadPage(emit, page: event.page);
    } finally {
      _goToPageBusy = false;
    }
  }

  Future<void> _onLoadMore(
    LoadMoreStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final current = state;
    if (current is! StoriesLoaded) return;
    if (current.hasReachedMax || _loadMoreBusy || _goToPageBusy) return;

    _loadMoreBusy = true;
    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _getStories(current.query.copyWith(page: nextPage));

    _loadMoreBusy = false;

    result.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingMore: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
        ),
      ),
      (page) {
        if (page.stories.isEmpty) {
          emit(
            current.copyWith(
              isLoadingMore: false,
              currentPage: page.totalPages,
              totalPages: page.totalPages,
              total: page.total,
            ),
          );
          return;
        }

        emit(
          current.copyWith(
            stories: [...current.stories, ...page.stories],
            currentPage: page.page,
            totalPages: page.totalPages,
            total: page.total,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onUpdate(
    UpdateStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final current = state;
    if (current is! StoriesLoaded) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true));
    final result = await _updateStory(event.params);

    result.fold(
      (failure) => emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
        ),
      ),
      (updated) {
        final stories = current.stories
            .map((story) => story.id == updated.id ? updated : story)
            .toList(growable: false);
        emit(
          current.copyWith(
            stories: stories,
            isMutating: false,
            feedbackMessage: 'storiesUpdateSuccess',
            feedbackIsError: false,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final current = state;
    if (current is! StoriesLoaded) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true));
    final result = await _deleteStory(event.storyId);

    result.fold(
      (failure) => emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
        ),
      ),
      (_) {
        final stories =
            current.stories.where((s) => s.id != event.storyId).toList();
        if (stories.isEmpty) {
          emit(
            StoriesEmpty(
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              selectedPrivacyStatus: _selectedPrivacyStatus,
              activeOnly: _activeOnly,
              userId: _userId,
              limit: _limit,
              feedbackMessage: 'storiesDeleteSuccess',
              feedbackIsError: false,
            ),
          );
          return;
        }

        emit(
          current.copyWith(
            stories: stories,
            total: current.total > 0 ? current.total - 1 : 0,
            isMutating: false,
            feedbackMessage: 'storiesDeleteSuccess',
            feedbackIsError: false,
          ),
        );
      },
    );
  }

  void _onChangeView(
    ChangeStoriesViewEvent event,
    Emitter<StoriesState> emit,
  ) {
    _useGridView = event.useGridView;
    final current = state;
    if (current is StoriesLoaded) {
      emit(current.copyWith(useGridView: _useGridView));
    }
  }

  void _onClearFeedback(
    ClearStoriesFeedbackEvent event,
    Emitter<StoriesState> emit,
  ) {
    final current = state;
    if (current is StoriesLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    } else if (current is StoriesEmpty && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<void> _onClearFilters(
    ClearStoriesFiltersEvent event,
    Emitter<StoriesState> emit,
  ) async {
    _searchQuery = null;
    _selectedStatus = null;
    _selectedPrivacyStatus = null;
    _activeOnly = null;
    _userId = null;
    await _loadPage(emit, page: 1);
  }

  bool get hasActiveFilters =>
      (_searchQuery?.isNotEmpty ?? false) ||
      _selectedStatus != null ||
      _selectedPrivacyStatus != null ||
      _activeOnly == true ||
      (_userId?.isNotEmpty ?? false);

  Future<void> _loadPage(
    Emitter<StoriesState> emit, {
    required int page,
    bool preserveLoadedShell = false,
  }) async {
    final current = state;
    if (preserveLoadedShell && current is StoriesLoaded) {
      emit(current.copyWith(isApplyingFilters: page == 1));
    } else if (current is StoriesLoaded && page == 1) {
      emit(current.copyWith(isApplyingFilters: true));
    } else if (current is! StoriesLoaded) {
      emit(StoriesLoading());
    }

    final myId = ++_loadRequestId;
    final query = _query.copyWith(page: page);
    final result = await _getStories(query);

    if (myId != _loadRequestId) return;

    result.fold(
      (failure) {
        if (current is StoriesLoaded) {
          emit(
            current.copyWith(
              isRefreshing: false,
              isApplyingFilters: false,
              feedbackMessage: failure.message,
              feedbackIsError: true,
            ),
          );
        } else {
          emit(StoriesError(failure.message));
        }
      },
      (pageResult) {
        if (pageResult.stories.isEmpty) {
          emit(
            StoriesEmpty(
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              selectedPrivacyStatus: _selectedPrivacyStatus,
              activeOnly: _activeOnly,
              userId: _userId,
              limit: _limit,
            ),
          );
          return;
        }

        emit(
          StoriesLoaded(
            stories: pageResult.stories,
            currentPage: pageResult.page,
            totalPages: pageResult.totalPages,
            total: pageResult.total,
            limit: _limit,
            searchQuery: _searchQuery,
            selectedStatus: _selectedStatus,
            selectedPrivacyStatus: _selectedPrivacyStatus,
            activeOnly: _activeOnly,
            userId: _userId,
            useGridView: _useGridView,
          ),
        );
      },
    );
  }
}
