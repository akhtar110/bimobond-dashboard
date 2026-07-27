import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post_filters.dart';

/// Immutable draft edited in the posts filter popup before Apply.
class PostsFilterDraftState extends Equatable {
  const PostsFilterDraftState({
    required this.postType,
    this.type,
    this.sort = PostFilters.defaultSort,
  });

  factory PostsFilterDraftState.fromFilters(PostFilters filters) {
    return PostsFilterDraftState(
      postType: filters.postTypeFilter,
      type: filters.type,
      sort: filters.sort ?? PostFilters.defaultSort,
    );
  }

  final PostTypeFilter postType;
  final String? type;
  final String sort;

  int get activeCount {
    var count = 0;
    if (postType != PostTypeFilter.all) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (sort != PostFilters.defaultSort) count++;
    return count;
  }

  PostsFilterDraftState copyWith({
    PostTypeFilter? postType,
    String? type,
    String? sort,
    bool clearType = false,
  }) {
    return PostsFilterDraftState(
      postType: postType ?? this.postType,
      type: clearType ? null : (type ?? this.type),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [postType, type, sort];
}

/// Dialog-scoped cubit for filter draft edits (Apply commits to [PostsBloc]).
class PostsFilterDraftCubit extends Cubit<PostsFilterDraftState> {
  PostsFilterDraftCubit(PostFilters filters)
      : super(PostsFilterDraftState.fromFilters(filters));

  void setPostType(PostTypeFilter value) {
    if (state.postType == value) return;
    emit(state.copyWith(postType: value));
  }

  void setType(String? value) {
    if (state.type == value) return;
    emit(state.copyWith(type: value, clearType: value == null));
  }

  void setSort(String value) {
    if (state.sort == value) return;
    emit(state.copyWith(sort: value));
  }

  void reset() {
    const next = PostsFilterDraftState(
      postType: PostTypeFilter.all,
      sort: PostFilters.defaultSort,
    );
    if (state == next) return;
    emit(next);
  }

  /// Builds the filters payload while preserving category + search from [base].
  PostFilters toAppliedFilters(PostFilters base) {
    return PostFilters(
      categoryId: base.categoryId,
      categoryName: base.categoryName,
      categorySlug: base.categorySlug,
      search: base.search,
      type: state.type,
      sort: state.sort,
      isAuctionable:
          state.postType == PostTypeFilter.auction ? true : null,
      isAd: state.postType == PostTypeFilter.ads ? true : null,
    );
  }
}
