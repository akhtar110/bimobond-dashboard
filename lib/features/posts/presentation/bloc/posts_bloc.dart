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
    on<UpdatePostFiltersEvent>(_onUpdateFilters);
    on<ClearPostFiltersEvent>(_onClearFilters);
  }

  final GetAllPosts getAllPosts;

  static const _limit = 20;
  bool _busy = false;
  PostFilters _filters = const PostFilters();

  PostFilters get activeFilters => _filters;

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
    final clear = event.categoryId == null &&
        event.categoryName == null &&
        event.categorySlug == null;
    _filters = _filters.copyWith(
      categoryId: event.categoryId,
      categoryName: event.categoryName,
      categorySlug: event.categorySlug,
      clearCategory: clear,
    );
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
    );
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<PostsState> emit) async {
    // ── Optimistic UI update ──────────────────────────────────────────
    // Always reflect the updated filters in state immediately so that
    // category chips (and any other filter UI) update without waiting
    // for the API call to complete.  This fixes the chip-not-selecting bug
    // that occurred when a load was already in flight (_busy == true).
    final current = state;
    if (current is PostsLoaded && current.filters != _filters) {
      emit(current.copyWith(isApplyingFilters: true, filters: _filters));
    }

    if (_busy) return;   // guard concurrent loads AFTER the UI is updated
    _busy = true;

    if (state is! PostsLoaded) {
      emit(PostsLoading());
    }

    try {
      final page = await getAllPosts(
        page: 1,
        limit: _limit,
        filters: _filters,
      );
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
      emit(PostsError(_messageFrom(e), filters: _filters));
    } finally {
      _busy = false;
    }
  }

  Future<void> _onLoadMore(
    LoadMorePostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final current = state;
    if (current is! PostsLoaded) return;
    if (current.hasReachedMax || _busy) return;

    _busy = true;
    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final page = await getAllPosts(
        page: nextPage,
        limit: _limit,
        filters: _filters,
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
      _busy = false;
    }
  }

  String _messageFrom(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
