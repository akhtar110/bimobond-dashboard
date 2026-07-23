import 'package:equatable/equatable.dart';

import '../../domain/entities/story_entity.dart';

abstract class StoriesState extends Equatable {
  const StoriesState();

  @override
  List<Object?> get props => [];
}

class StoriesInitial extends StoriesState {}

class StoriesLoading extends StoriesState {}

class StoriesLoaded extends StoriesState {
  const StoriesLoaded({
    required this.stories,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.limit,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedPrivacyStatus,
    required this.activeOnly,
    required this.userId,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isApplyingFilters = false,
    this.isMutating = false,
    this.useGridView = true,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<StoryEntity> stories;
  final int currentPage;
  final int totalPages;
  final int total;
  final int limit;
  final String? searchQuery;
  final String? selectedStatus;
  final String? selectedPrivacyStatus;
  final bool? activeOnly;
  final String? userId;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isApplyingFilters;
  final bool isMutating;
  final bool useGridView;
  final String? feedbackMessage;
  final bool feedbackIsError;

  bool get loading => isRefreshing || isApplyingFilters;

  bool get hasReachedMax => currentPage >= totalPages;

  StoryQuery get query => StoryQuery(
        page: currentPage,
        limit: limit,
        search: searchQuery,
        status: selectedStatus,
        privacyStatus: selectedPrivacyStatus,
        activeOnly: activeOnly,
        userId: userId,
      );

  StoriesLoaded copyWith({
    List<StoryEntity>? stories,
    int? currentPage,
    int? totalPages,
    int? total,
    int? limit,
    String? searchQuery,
    String? selectedStatus,
    String? selectedPrivacyStatus,
    bool? activeOnly,
    String? userId,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isApplyingFilters,
    bool? isMutating,
    bool? useGridView,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearPrivacyStatus = false,
    bool clearActiveOnly = false,
    bool clearUserId = false,
  }) {
    return StoriesLoaded(
      stories: stories ?? this.stories,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedPrivacyStatus: clearPrivacyStatus
          ? null
          : (selectedPrivacyStatus ?? this.selectedPrivacyStatus),
      activeOnly:
          clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
      userId: clearUserId ? null : (userId ?? this.userId),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isApplyingFilters: isApplyingFilters ?? this.isApplyingFilters,
      isMutating: isMutating ?? this.isMutating,
      useGridView: useGridView ?? this.useGridView,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props => [
        stories,
        currentPage,
        totalPages,
        total,
        limit,
        searchQuery,
        selectedStatus,
        selectedPrivacyStatus,
        activeOnly,
        userId,
        isRefreshing,
        isLoadingMore,
        isApplyingFilters,
        isMutating,
        useGridView,
        feedbackMessage,
        feedbackIsError,
      ];
}

class StoriesEmpty extends StoriesState {
  const StoriesEmpty({
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedPrivacyStatus,
    required this.activeOnly,
    required this.userId,
    required this.limit,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final String? searchQuery;
  final String? selectedStatus;
  final String? selectedPrivacyStatus;
  final bool? activeOnly;
  final String? userId;
  final int limit;
  final String? feedbackMessage;
  final bool feedbackIsError;

  StoriesEmpty copyWith({
    String? searchQuery,
    String? selectedStatus,
    String? selectedPrivacyStatus,
    bool? activeOnly,
    String? userId,
    int? limit,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return StoriesEmpty(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedPrivacyStatus:
          selectedPrivacyStatus ?? this.selectedPrivacyStatus,
      activeOnly: activeOnly ?? this.activeOnly,
      userId: userId ?? this.userId,
      limit: limit ?? this.limit,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        selectedStatus,
        selectedPrivacyStatus,
        activeOnly,
        userId,
        limit,
        feedbackMessage,
        feedbackIsError,
      ];
}

class StoriesError extends StoriesState {
  const StoriesError(this.message, {this.previous});

  final String message;
  final StoriesLoaded? previous;

  @override
  List<Object?> get props => [message, previous];
}
