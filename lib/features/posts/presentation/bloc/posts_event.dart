part of 'posts_bloc.dart';

sealed class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

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
  final String? categorySlug;

  @override
  List<Object?> get props => [categoryId, categoryName, categorySlug];
}

class SearchPostsEvent extends PostsEvent {
  const SearchPostsEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterPostsByTypeEvent extends PostsEvent {
  FilterPostsByTypeEvent({
    this.isAuctionable,
    this.isStory,
    this.isAd,
  });

  final bool? isAuctionable;
  final bool? isStory;
  final bool? isAd;

  @override
  List<Object?> get props => [isAuctionable, isStory, isAd];
}

class UpdatePostFiltersEvent extends PostsEvent {
  const UpdatePostFiltersEvent(this.filters);
  final PostFilters filters;

  @override
  List<Object?> get props => [filters];
}

class ClearPostFiltersEvent extends PostsEvent {}

class PatchPostEvent extends PostsEvent {
  const PatchPostEvent(this.updatedPost);
  final ManagedPostEntity updatedPost;

  @override
  List<Object?> get props => [updatedPost];
}

class RemovePostEvent extends PostsEvent {
  const RemovePostEvent(this.postId);
  final String postId;

  @override
  List<Object?> get props => [postId];
}

// ── View ────────────────────────────────────────────────────────────────────

class ChangePostsViewEvent extends PostsEvent {
  const ChangePostsViewEvent(this.viewType);
  final PostsViewType viewType;

  @override
  List<Object?> get props => [viewType];
}

// ── Selection ───────────────────────────────────────────────────────────────

class SelectPostEvent extends PostsEvent {
  const SelectPostEvent(this.postId);
  final String postId;

  @override
  List<Object?> get props => [postId];
}

class DeselectPostEvent extends PostsEvent {
  const DeselectPostEvent(this.postId);
  final String postId;

  @override
  List<Object?> get props => [postId];
}

class SelectAllPostsEvent extends PostsEvent {}

class ClearSelectionEvent extends PostsEvent {}

class ClearBulkActionFeedbackEvent extends PostsEvent {}

// ── Bulk actions ────────────────────────────────────────────────────────────

class PublishSelectedPostsEvent extends PostsEvent {}

class DraftSelectedPostsEvent extends PostsEvent {}

class HideSelectedPostsEvent extends PostsEvent {}

class UnderReviewSelectedPostsEvent extends PostsEvent {}

class ArchiveSelectedPostsEvent extends PostsEvent {}

class BanSelectedPostsEvent extends PostsEvent {}

class UnbanSelectedPostsEvent extends PostsEvent {}

class DeleteSelectedPostsEvent extends PostsEvent {}

class PermanentlyDeleteSelectedPostsEvent extends PostsEvent {}

class EnableCommentsSelectedPostsEvent extends PostsEvent {}

class DisableCommentsSelectedPostsEvent extends PostsEvent {}

class EnableDuetsSelectedPostsEvent extends PostsEvent {}

class DisableDuetsSelectedPostsEvent extends PostsEvent {}

class EnableStitchSelectedPostsEvent extends PostsEvent {}

class DisableStitchSelectedPostsEvent extends PostsEvent {}

class FeatureSelectedPostsEvent extends PostsEvent {}

class UnfeatureSelectedPostsEvent extends PostsEvent {}

class SetPublicSelectedPostsEvent extends PostsEvent {}

class SetPrivateSelectedPostsEvent extends PostsEvent {}

class SetFollowersOnlySelectedPostsEvent extends PostsEvent {}
