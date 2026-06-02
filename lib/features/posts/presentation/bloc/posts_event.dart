part of 'posts_bloc.dart';

sealed class PostsEvent {}

class GetAllPostsEvent extends PostsEvent {}

class LoadMorePostsEvent extends PostsEvent {}

class FilterPostsByCategoryEvent extends PostsEvent {
  FilterPostsByCategoryEvent({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
  });
  final String? categoryId;
  final String? categoryName;
  /// Slug sent to the API (e.g. `"music"`).
  final String? categorySlug;
}

class UpdatePostFiltersEvent extends PostsEvent {
  UpdatePostFiltersEvent(this.filters);
  final PostFilters filters;
}

class ClearPostFiltersEvent extends PostsEvent {}
