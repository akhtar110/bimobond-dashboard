part of 'posts_bloc.dart';

sealed class PostsState {}

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
  });

  final List<ManagedPostEntity> posts;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isApplyingFilters;
  final PostFilters filters;

  String? get selectedCategoryId => filters.categoryId;
  String? get selectedCategoryName => filters.categoryName;

  PostsLoaded copyWith({
    List<ManagedPostEntity>? posts,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isApplyingFilters,
    PostFilters? filters,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isApplyingFilters: isApplyingFilters ?? this.isApplyingFilters,
      filters: filters ?? this.filters,
    );
  }
}

class PostsEmpty extends PostsState {
  PostsEmpty(this.filters);
  final PostFilters filters;
}

class PostsError extends PostsState {
  PostsError(this.message, {this.filters});
  final String message;
  final PostFilters? filters;
}
