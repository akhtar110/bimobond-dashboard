part of 'posts_bloc.dart';

sealed class PostsEvent {}

/// Load the first page with no filters (or refresh after a post is created).
class GetAllPostsEvent extends PostsEvent {}

/// Append the next page using the currently active filters.
class LoadMorePostsEvent extends PostsEvent {}

/// Select a category chip — pass no arguments to clear the category filter.
class FilterPostsByCategoryEvent extends PostsEvent {
  FilterPostsByCategoryEvent({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
  });
  final String? categoryId;
  final String? categoryName;

  /// Slug sent to the API `?category=` param (e.g. `"music"`).
  final String? categorySlug;
}

/// Dedicated search event.  Pass an empty string to clear the search filter.
/// Preserves all currently active filters (category, type, sort, etc.).
class SearchPostsEvent extends PostsEvent {
  SearchPostsEvent(this.query);
  final String query;
}

/// Bulk-replace all advanced filters at once (type, sort, isAuctionable).
/// Must be constructed from [PostsBloc.activeFilters] so category is preserved.
class UpdatePostFiltersEvent extends PostsEvent {
  UpdatePostFiltersEvent(this.filters);
  final PostFilters filters;
}

/// Reset search, type, sort, and isAuctionable — keep the selected category.
class ClearPostFiltersEvent extends PostsEvent {}

/// Patch a single post in the loaded list without re-fetching the entire page.
/// Dispatched by PostsPage after a successful save in PostManagementDetailScreen.
class PatchPostEvent extends PostsEvent {
  PatchPostEvent(this.updatedPost);
  final ManagedPostEntity updatedPost;
}
