import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_filters.dart';
import '../../domain/usecases/get_all_posts_usecase.dart';

part 'posts_event.dart';
part 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc({required this.getAllPosts}) : super(PostsInitial()) {
    on<GetAllPostsEvent>(_onGetAll);
    on<LoadMorePostsEvent>(_onLoadMore);
    on<FilterPostsByCategoryEvent>(_onFilterCategory);
    on<SearchPostsEvent>(_onSearch);
    on<UpdatePostFiltersEvent>(_onUpdateFilters);
    on<ClearPostFiltersEvent>(_onClearFilters);
    on<PatchPostEvent>(_onPatchPost);
    on<RemovePostEvent>(_onRemovePost);
  }

  final GetAllPosts getAllPosts;

  static const _limit = 20;

  // ── Request-ID counter ────────────────────────────────────────────────────
  // Every call to _loadFirstPage increments this counter and captures its own
  // snapshot.  When the API responds, we compare the snapshot against the
  // current counter.  If they differ a newer request is already in-flight and
  // we discard this response — this replaces the old `_busy` boolean which was
  // causing filter events to be silently swallowed whenever a load was running.
  int _loadRequestId = 0;

  // Separate guard only for load-more to stop duplicate pagination calls.
  bool _loadMoreBusy = false;

  PostFilters _filters = const PostFilters();

  PostFilters get activeFilters => _filters;

  // ── Event handlers ────────────────────────────────────────────────────────

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

    if (kDebugMode) {
      debugPrint(
        '[PostsBloc] filterCategory → '
        'id=${event.categoryId}  '
        'name=${event.categoryName}  '
        'slug=${event.categorySlug}  '
        'isAll=$isAll',
      );
    }

    if (isAll) {
      // "All" chip — clear category filter, keep all other filters intact.
      _filters = _filters.copyWith(clearCategory: true);
    } else {
      // Specific category selected. Rebuild filters wholesale so we can
      // replace the category triple (id, name, slug) without the copyWith
      // null-means-keep-old ambiguity.  Empty string id is normalised to null
      // so the datasource does not send a blank ?categoryId= parameter.
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
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[PostsBloc] _filters after update → '
        'categoryId=${_filters.categoryId}  '
        'categorySlug=${_filters.categorySlug}',
      );
    }

    await _loadFirstPage(emit);
  }

  Future<void> _onSearch(
    SearchPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final trimmed = event.query.trim();
    // Build new filters by merging the search term into the existing filters
    // so that the active category, type, sort etc. are all preserved.
    final updated = _filters.copyWith(
      search: trimmed.isEmpty ? null : trimmed,
      clearSearch: trimmed.isEmpty,
    );
    if (_filters == updated) return; // nothing changed
    _filters = updated;

    if (kDebugMode) {
      debugPrint('[PostsBloc] search → "${trimmed.isEmpty ? '<cleared>' : trimmed}"');
    }

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
    // Keep the active category chip (id + name + slug) — "Clear filters"
    // only resets the search bar, type, sort, and auction toggles.
    // Bug-fix: was previously dropping categorySlug, breaking the next
    // API call even though the chip remained visually selected.
    _filters = PostFilters(
      categoryId: _filters.categoryId,
      categoryName: _filters.categoryName,
      categorySlug: _filters.categorySlug,
    );
    await _loadFirstPage(emit);
  }

  // ── Core loader ───────────────────────────────────────────────────────────

  Future<void> _loadFirstPage(Emitter<PostsState> emit) async {
    // Optimistic UI: reflect the new filters immediately so the category chip
    // appears selected / the filter bar updates without waiting for the API.
    final current = state;
    if (current is PostsLoaded && current.filters != _filters) {
      emit(current.copyWith(isApplyingFilters: true, filters: _filters));
    } else if (current is! PostsLoaded) {
      emit(PostsLoading());
    }

    // Capture a snapshot of request ID and filters at this exact moment.
    // If another filter event fires concurrently it will increment _loadRequestId;
    // when this request finishes we'll detect the mismatch and discard our response.
    final myId = ++_loadRequestId;
    final filtersSnapshot = _filters;

    if (kDebugMode) {
      debugPrint(
        '[PostsBloc] load #$myId  '
        'categoryId=${filtersSnapshot.categoryId}  '
        'categorySlug=${filtersSnapshot.categorySlug}  '
        'search=${filtersSnapshot.search}  '
        'type=${filtersSnapshot.type}  '
        'sort=${filtersSnapshot.sort}',
      );
    }

    try {
      final page = await getAllPosts(
        page: 1,
        limit: _limit,
        filters: filtersSnapshot,
      );

      // Discard stale responses: a newer request is already in flight.
      if (myId != _loadRequestId) {
        if (kDebugMode) {
          debugPrint(
            '[PostsBloc] discarding stale response #$myId '
            '(latest is #$_loadRequestId)',
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[PostsBloc] #$myId resolved → ${page.posts.length} posts '
          '(page ${page.currentPage}/${page.lastPage})',
        );
      }

      if (page.posts.isEmpty) {
        emit(PostsEmpty(_filters));
      } else {
        emit(
          PostsLoaded(
            posts: page.posts,
            currentPage: page.currentPage,
            hasReachedMax: page.hasReachedMax,
            filters: _filters,
            isApplyingFilters: false,
          ),
        );
      }
    } catch (e) {
      if (myId != _loadRequestId) return; // stale error — ignore
      if (kDebugMode) debugPrint('[PostsBloc] #$myId error: $e');
      emit(PostsError(_messageFrom(e), filters: _filters));
    }
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  Future<void> _onLoadMore(
    LoadMorePostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final current = state;
    if (current is! PostsLoaded) return;
    if (current.hasReachedMax || _loadMoreBusy) return;

    _loadMoreBusy = true;
    emit(current.copyWith(isLoadingMore: true));

    if (kDebugMode) {
      debugPrint(
        '[PostsBloc] loadMore → page ${current.currentPage + 1}  '
        'category=${_filters.categorySlug}  '
        'search=${_filters.search}',
      );
    }

    try {
      final nextPage = current.currentPage + 1;
      final page = await getAllPosts(
        page: nextPage,
        limit: _limit,
        filters: _filters,   // Always uses the CURRENT filters, never stale
      );
      emit(
        current.copyWith(
          posts: [...current.posts, ...page.posts],
          currentPage: page.currentPage,
          hasReachedMax: page.hasReachedMax,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    } finally {
      _loadMoreBusy = false;
    }
  }

  // ── Single-post patch ────────────────────────────────────────────────────
  // Called after a successful save in PostManagementDetailScreen so the list
  // reflects the new values instantly, without a full page reload.

  void _onPatchPost(PatchPostEvent event, Emitter<PostsState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    final updated = current.posts.map(
      (p) => p.id == event.updatedPost.id ? event.updatedPost : p,
    ).toList();
    emit(current.copyWith(posts: updated));
  }

  void _onRemovePost(RemovePostEvent event, Emitter<PostsState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    final remaining = current.posts.where((p) => p.id != event.postId).toList();
    if (remaining.isEmpty) {
      emit(PostsEmpty(_filters));
    } else {
      emit(current.copyWith(posts: remaining));
    }
  }

  String _messageFrom(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
