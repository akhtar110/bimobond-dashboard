import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/entities/bulk_post_action_request.dart';
import '../../domain/entities/post_filters.dart';
import '../../domain/enums/bulk_post_action_type.dart';
import '../../domain/enums/posts_view_type.dart';
import '../../domain/utils/bulk_post_local_update.dart';
import '../../domain/usecases/bulk_post_action_usecase.dart';
import '../../domain/usecases/get_all_posts_usecase.dart';

part 'posts_event.dart';
part 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc({
    required this.getAllPosts,
    required this.bulkPostAction,
  }) : super(PostsInitial()) {
    on<GetAllPostsEvent>(_onGetAll);
    on<LoadMorePostsEvent>(_onLoadMore);
    on<GoToPostsPageEvent>(_onGoToPage);
    on<FilterPostsByCategoryEvent>(_onFilterCategory);
    on<FilterPostsByTypeEvent>(_onFilterByType);
    on<SearchPostsEvent>(_onSearch);
    on<UpdatePostFiltersEvent>(_onUpdateFilters);
    on<ClearPostFiltersEvent>(_onClearFilters);
    on<PatchPostEvent>(_onPatchPost);
    on<RemovePostEvent>(_onRemovePost);
    on<ChangePostsViewEvent>(_onChangeView);
    on<SelectPostEvent>(_onSelectPost);
    on<DeselectPostEvent>(_onDeselectPost);
    on<SelectAllPostsEvent>(_onSelectAllPosts);
    on<ClearSelectionEvent>(_onClearSelection);
    on<ClearBulkActionFeedbackEvent>(_onClearBulkFeedback);
    on<PublishSelectedPostsEvent>(_onBulkAction);
    on<DraftSelectedPostsEvent>(_onBulkAction);
    on<HideSelectedPostsEvent>(_onBulkAction);
    on<UnderReviewSelectedPostsEvent>(_onBulkAction);
    on<ArchiveSelectedPostsEvent>(_onBulkAction);
    on<BanSelectedPostsEvent>(_onBulkAction);
    on<UnbanSelectedPostsEvent>(_onBulkAction);
    on<DeleteSelectedPostsEvent>(_onBulkAction);
    on<PermanentlyDeleteSelectedPostsEvent>(_onBulkAction);
    on<EnableCommentsSelectedPostsEvent>(_onBulkAction);
    on<DisableCommentsSelectedPostsEvent>(_onBulkAction);
    on<EnableDuetsSelectedPostsEvent>(_onBulkAction);
    on<DisableDuetsSelectedPostsEvent>(_onBulkAction);
    on<EnableStitchSelectedPostsEvent>(_onBulkAction);
    on<DisableStitchSelectedPostsEvent>(_onBulkAction);
    on<FeatureSelectedPostsEvent>(_onBulkAction);
    on<UnfeatureSelectedPostsEvent>(_onBulkAction);
    on<SetPublicSelectedPostsEvent>(_onBulkAction);
    on<SetPrivateSelectedPostsEvent>(_onBulkAction);
    on<SetFollowersOnlySelectedPostsEvent>(_onBulkAction);
  }

  final GetAllPosts getAllPosts;
  final BulkPostActionUseCase bulkPostAction;

  static const pageLimit = 20;
  static const _limit = pageLimit;

  int _loadRequestId = 0;
  bool _loadMoreBusy = false;
  bool _goToPageBusy = false;

  PostFilters _filters = const PostFilters();
  PostsViewType _viewType = PostsViewType.grid;
  Set<String> _selectedPostIds = {};

  PostFilters get activeFilters => _filters;
  PostsViewType get activeViewType => _viewType;
  Set<String> get selectedPostIds => Set.unmodifiable(_selectedPostIds);

  // ── View & selection ─────────────────────────────────────────────────────

  void _onChangeView(ChangePostsViewEvent event, Emitter<PostsState> emit) {
    if (_viewType == event.viewType) return;
    _viewType = event.viewType;
    _emitWithUiState(emit);
  }

  void _onSelectPost(SelectPostEvent event, Emitter<PostsState> emit) {
    _selectedPostIds = {..._selectedPostIds, event.postId};
    _emitWithUiState(emit);
  }

  void _onDeselectPost(DeselectPostEvent event, Emitter<PostsState> emit) {
    _selectedPostIds = {..._selectedPostIds}..remove(event.postId);
    _emitWithUiState(emit);
  }

  void _onSelectAllPosts(SelectAllPostsEvent event, Emitter<PostsState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    final visibleIds = current.posts.map((p) => p.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedPostIds.contains);
    if (allVisibleSelected) {
      _selectedPostIds = _selectedPostIds.difference(visibleIds);
    } else {
      _selectedPostIds = {..._selectedPostIds, ...visibleIds};
    }
    _emitWithUiState(emit);
  }

  void _onClearSelection(ClearSelectionEvent event, Emitter<PostsState> emit) {
    if (_selectedPostIds.isEmpty) return;
    _selectedPostIds = {};
    _emitWithUiState(emit);
  }

  void _onClearBulkFeedback(
    ClearBulkActionFeedbackEvent event,
    Emitter<PostsState> emit,
  ) {
    final current = state;
    if (current is PostsLoaded && current.bulkActionMessage != null) {
      emit(current.copyWith(clearBulkActionMessage: true));
    }
  }

  void _emitWithUiState(Emitter<PostsState> emit) {
    final current = state;
    if (current is PostsLoaded) {
      emit(_withUiState(current));
    }
  }

  PostsLoaded _withUiState(PostsLoaded current, {PostsLoaded Function(PostsLoaded)? patch}) {
    final base = patch != null ? patch(current) : current;
    return base.copyWith(
      viewType: _viewType,
      selectedPostIds: Set<String>.from(_selectedPostIds),
    );
  }

  // ── Bulk actions ─────────────────────────────────────────────────────────

  Future<void> _onBulkAction(PostsEvent event, Emitter<PostsState> emit) async {
    final current = state;
    if (current is! PostsLoaded || _selectedPostIds.isEmpty) return;

    final action = _actionForEvent(event);
    if (action == null) return;

    final ids = _selectedPostIds.toList(growable: false);
    emit(
      _withUiState(
        current.copyWith(
          isPerformingBulkAction: true,
          clearBulkActionMessage: true,
        ),
      ),
    );

    try {
      final result = await bulkPostAction(
        BulkPostActionRequest(postIds: ids, action: action),
      );

      final updatedById = {
        for (final post in result.updatedPosts) post.id: post,
      };
      final succeededIds = result.succeededPostIds.toSet();
      var posts = current.posts
          .where((p) => !result.removedPostIds.contains(p.id))
          .map((p) {
            final updated = updatedById[p.id];
            if (updated != null) return updated;
            if (succeededIds.contains(p.id)) {
              return applyBulkPostLocalUpdate(p, action);
            }
            return p;
          })
          .toList();

      _selectedPostIds = _selectedPostIds
          .difference(result.removedPostIds.toSet())
          .difference(result.failedPostIds.toSet());

      final message = result.isFullSuccess
          ? _successMessageFor(action, result.successCount)
          : result.errorMessage ??
              '${result.failedPostIds.length} post(s) failed';

      if (posts.isEmpty) {
        emit(PostsEmpty(_filters));
      } else {
        emit(
          _withUiState(
            current.copyWith(
              posts: posts,
              isPerformingBulkAction: false,
              bulkActionMessage: message,
              bulkActionIsError: !result.isFullSuccess,
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        _withUiState(
          current.copyWith(
            isPerformingBulkAction: false,
            bulkActionMessage: _messageFrom(e),
            bulkActionIsError: true,
          ),
        ),
      );
    }
  }

  BulkPostActionType? _actionForEvent(PostsEvent event) => switch (event) {
        PublishSelectedPostsEvent() => BulkPostActionType.publish,
        DraftSelectedPostsEvent() => BulkPostActionType.draft,
        HideSelectedPostsEvent() => BulkPostActionType.hide,
        UnderReviewSelectedPostsEvent() => BulkPostActionType.underReview,
        ArchiveSelectedPostsEvent() => BulkPostActionType.archive,
        BanSelectedPostsEvent() => BulkPostActionType.ban,
        UnbanSelectedPostsEvent() => BulkPostActionType.unban,
        DeleteSelectedPostsEvent() => BulkPostActionType.softDelete,
        PermanentlyDeleteSelectedPostsEvent() =>
          BulkPostActionType.permanentDelete,
        EnableCommentsSelectedPostsEvent() => BulkPostActionType.enableComments,
        DisableCommentsSelectedPostsEvent() =>
          BulkPostActionType.disableComments,
        EnableDuetsSelectedPostsEvent() => BulkPostActionType.enableDuets,
        DisableDuetsSelectedPostsEvent() => BulkPostActionType.disableDuets,
        EnableStitchSelectedPostsEvent() => BulkPostActionType.enableStitch,
        DisableStitchSelectedPostsEvent() => BulkPostActionType.disableStitch,
        FeatureSelectedPostsEvent() => BulkPostActionType.feature,
        UnfeatureSelectedPostsEvent() => BulkPostActionType.unfeature,
        SetPublicSelectedPostsEvent() => BulkPostActionType.setPublic,
        SetPrivateSelectedPostsEvent() => BulkPostActionType.setPrivate,
        SetFollowersOnlySelectedPostsEvent() =>
          BulkPostActionType.setFollowersOnly,
        _ => null,
      };

  String _successMessageFor(BulkPostActionType action, int count) {
    final label = switch (action) {
      BulkPostActionType.publish => 'published',
      BulkPostActionType.draft => 'saved as draft',
      BulkPostActionType.hide => 'hidden',
      BulkPostActionType.underReview => 'marked under review',
      BulkPostActionType.archive => 'archived',
      BulkPostActionType.ban => 'banned',
      BulkPostActionType.unban => 'unbanned',
      BulkPostActionType.softDelete => 'deleted',
      BulkPostActionType.permanentDelete => 'permanently deleted',
      BulkPostActionType.enableComments => 'comments enabled',
      BulkPostActionType.disableComments => 'comments disabled',
      BulkPostActionType.enableDuets => 'duets enabled',
      BulkPostActionType.disableDuets => 'duets disabled',
      BulkPostActionType.enableStitch => 'stitch enabled',
      BulkPostActionType.disableStitch => 'stitch disabled',
      BulkPostActionType.feature => 'featured',
      BulkPostActionType.unfeature => 'unfeatured',
      BulkPostActionType.setPublic => 'set to public',
      BulkPostActionType.setPrivate => 'set to private',
      BulkPostActionType.setFollowersOnly => 'set to followers only',
    };
    return '$count post(s) $label';
  }

  // ── Existing handlers ────────────────────────────────────────────────────

  Future<void> _onGetAll(
    GetAllPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    await _loadFirstPage(emit);
  }

  Future<void> _onFilterCategory(
    FilterPostsByCategoryEvent event,
    Emitter<PostsState> emit,
  ) async {
    final isAll = event.categoryId == null &&
        event.categoryName == null &&
        event.categorySlug == null;

    if (isAll) {
      _filters = _filters.copyWith(clearCategory: true);
    } else {
      final effectiveId = (event.categoryId?.trim().isEmpty ?? true)
          ? null
          : event.categoryId;
      _filters = PostFilters(
        categoryId: effectiveId,
        categoryName: event.categoryName,
        categorySlug: event.categorySlug,
        search: _filters.search,
        type: _filters.type,
        sort: _filters.sort,
        isAuctionable: _filters.isAuctionable,
        isStory: _filters.isStory,
        isAd: _filters.isAd,
      );
    }

    await _loadFirstPage(emit);
  }

  Future<void> _onFilterByType(
    FilterPostsByTypeEvent event,
    Emitter<PostsState> emit,
  ) async {
    _filters = _filters.copyWith(
      isAuctionable: event.isAuctionable,
      isStory: event.isStory,
      isAd: event.isAd,
      clearAuction: event.isAuctionable == null,
      clearStory: event.isStory == null,
      clearAd: event.isAd == null,
    );

    await _loadFirstPage(emit);
  }

  Future<void> _onSearch(
    SearchPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final trimmed = event.query.trim();
    final updated = _filters.copyWith(
      search: trimmed.isEmpty ? null : trimmed,
      clearSearch: trimmed.isEmpty,
    );
    if (_filters == updated) return;
    _filters = updated;
    await _loadFirstPage(emit);
  }

  Future<void> _onUpdateFilters(
    UpdatePostFiltersEvent event,
    Emitter<PostsState> emit,
  ) async {
    if (_filters == event.filters) return;
    _filters = event.filters;
    await _loadFirstPage(emit);
  }

  Future<void> _onClearFilters(
    ClearPostFiltersEvent event,
    Emitter<PostsState> emit,
  ) async {
    _filters = PostFilters(
      categoryId: _filters.categoryId,
      categoryName: _filters.categoryName,
      categorySlug: _filters.categorySlug,
    );
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<PostsState> emit) async {
    final current = state;
    if (current is PostsLoaded && current.filters != _filters) {
      emit(
        _withUiState(
          current.copyWith(isApplyingFilters: true, filters: _filters),
        ),
      );
    } else if (current is! PostsLoaded) {
      emit(PostsLoading());
    }

    final myId = ++_loadRequestId;
    final filtersSnapshot = _filters;

    try {
      final page = await getAllPosts(
        page: 1,
        limit: _limit,
        filters: filtersSnapshot,
      );

      if (myId != _loadRequestId) return;

      if (page.posts.isEmpty) {
        emit(PostsEmpty(_filters));
      } else {
        emit(
          PostsLoaded(
            posts: page.posts,
            currentPage: page.currentPage,
            lastPage: page.lastPage,
            total: page.total,
            hasReachedMax: page.hasReachedMax,
            filters: _filters,
            isApplyingFilters: false,
            viewType: _viewType,
            selectedPostIds: Set<String>.from(_selectedPostIds),
          ),
        );
      }
    } catch (e) {
      if (myId != _loadRequestId) return;
      emit(PostsError(_messageFrom(e), filters: _filters));
    }
  }

  Future<void> _onLoadMore(
    LoadMorePostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final current = state;
    if (current is! PostsLoaded) return;
    if (current.hasReachedMax || _loadMoreBusy || _goToPageBusy) return;

    _loadMoreBusy = true;
    emit(_withUiState(current.copyWith(isLoadingMore: true)));

    try {
      final nextPage = current.currentPage + 1;
      final page = await getAllPosts(
        page: nextPage,
        limit: _limit,
        filters: _filters,
      );
      emit(
        _withUiState(
          current.copyWith(
            posts: [...current.posts, ...page.posts],
            currentPage: page.currentPage,
            lastPage: page.lastPage,
            total: page.total,
            hasReachedMax: page.hasReachedMax,
            isLoadingMore: false,
          ),
        ),
      );
    } catch (_) {
      emit(_withUiState(current.copyWith(isLoadingMore: false)));
    } finally {
      _loadMoreBusy = false;
    }
  }

  Future<void> _onGoToPage(
    GoToPostsPageEvent event,
    Emitter<PostsState> emit,
  ) async {
    if (event.page < 1 || _goToPageBusy || _loadMoreBusy) return;

    final current = state;
    if (current is PostsLoaded) {
      if (event.page == current.currentPage &&
          current.posts.length <= _limit) {
        return;
      }
      _goToPageBusy = true;
      emit(
        _withUiState(
          current.copyWith(isApplyingFilters: true, isLoadingMore: false),
        ),
      );
    } else {
      _goToPageBusy = true;
      emit(PostsLoading());
    }

    final myId = ++_loadRequestId;
    final filtersSnapshot = _filters;

    try {
      final page = await getAllPosts(
        page: event.page,
        limit: _limit,
        filters: filtersSnapshot,
      );

      if (myId != _loadRequestId) return;

      _selectedPostIds = {};

      if (page.posts.isEmpty) {
        emit(PostsEmpty(_filters));
      } else {
        emit(
          PostsLoaded(
            posts: page.posts,
            currentPage: page.currentPage,
            lastPage: page.lastPage,
            total: page.total,
            hasReachedMax: page.hasReachedMax,
            filters: _filters,
            isApplyingFilters: false,
            viewType: _viewType,
            selectedPostIds: const {},
          ),
        );
      }
    } catch (e) {
      if (myId != _loadRequestId) return;
      if (current is PostsLoaded) {
        emit(
          _withUiState(
            current.copyWith(isApplyingFilters: false, isLoadingMore: false),
          ),
        );
      } else {
        emit(PostsError(_messageFrom(e), filters: _filters));
      }
    } finally {
      _goToPageBusy = false;
    }
  }

  void _onPatchPost(PatchPostEvent event, Emitter<PostsState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    final updated = current.posts
        .map(
          (p) => p.id == event.updatedPost.id ? event.updatedPost : p,
        )
        .toList(growable: false);
    emit(_withUiState(current.copyWith(posts: updated)));
  }

  void _onRemovePost(RemovePostEvent event, Emitter<PostsState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    _selectedPostIds = {..._selectedPostIds}..remove(event.postId);
    final remaining =
        current.posts.where((p) => p.id != event.postId).toList();
    if (remaining.isEmpty) {
      emit(PostsEmpty(_filters));
    } else {
      emit(_withUiState(current.copyWith(posts: remaining)));
    }
  }

  String _messageFrom(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
