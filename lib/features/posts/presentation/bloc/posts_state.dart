part of 'posts_bloc.dart';

sealed class PostsState extends Equatable {
  const PostsState();

  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  PostsLoaded({
    required this.posts,
    required this.currentPage,
    required this.hasReachedMax,
    required this.filters,
    this.isLoadingMore = false,
    this.isApplyingFilters = false,
    this.viewType = PostsViewType.grid,
    Set<String>? selectedPostIds,
    this.isPerformingBulkAction = false,
    this.bulkActionMessage,
    this.bulkActionIsError = false,
  }) : selectedPostIds = Set.unmodifiable(selectedPostIds ?? const {});

  final List<ManagedPostEntity> posts;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isApplyingFilters;
  final PostFilters filters;
  final PostsViewType viewType;
  final Set<String> selectedPostIds;
  final bool isPerformingBulkAction;
  final String? bulkActionMessage;
  final bool bulkActionIsError;

  String? get selectedCategoryId => filters.categoryId;
  String? get selectedCategoryName => filters.categoryName;
  bool get isSelectionMode => selectedPostIds.isNotEmpty;
  int get selectedCount => selectedPostIds.length;

  bool get allVisibleSelected {
    if (posts.isEmpty) return false;
    return posts.every((p) => selectedPostIds.contains(p.id));
  }

  bool get someVisibleSelected =>
      posts.any((p) => selectedPostIds.contains(p.id));

  PostsLoaded copyWith({
    List<ManagedPostEntity>? posts,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isApplyingFilters,
    PostFilters? filters,
    PostsViewType? viewType,
    Set<String>? selectedPostIds,
    bool? isPerformingBulkAction,
    String? bulkActionMessage,
    bool? bulkActionIsError,
    bool clearBulkActionMessage = false,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isApplyingFilters: isApplyingFilters ?? this.isApplyingFilters,
      filters: filters ?? this.filters,
      viewType: viewType ?? this.viewType,
      selectedPostIds: selectedPostIds ?? this.selectedPostIds,
      isPerformingBulkAction:
          isPerformingBulkAction ?? this.isPerformingBulkAction,
      bulkActionMessage: clearBulkActionMessage
          ? null
          : (bulkActionMessage ?? this.bulkActionMessage),
      bulkActionIsError: bulkActionIsError ?? this.bulkActionIsError,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        isApplyingFilters,
        filters,
        viewType,
        selectedPostIds,
        isPerformingBulkAction,
        bulkActionMessage,
        bulkActionIsError,
      ];
}

class PostsEmpty extends PostsState {
  const PostsEmpty(this.filters);
  final PostFilters filters;

  @override
  List<Object?> get props => [filters];
}

class PostsError extends PostsState {
  const PostsError(this.message, {this.filters});
  final String message;
  final PostFilters? filters;

  @override
  List<Object?> get props => [message, filters];
}
