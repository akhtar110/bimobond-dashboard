import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/pagination_meta.dart';
import 'paginated_list_state.dart';

typedef PaginatedFetch<T> = Future<PaginatedPage<T>> Function(
  String userId,
  int page,
  int limit,
);

class PaginatedListBlocHelper {
  static const int defaultLimit = 10;

  static Future<PaginatedListState<T>> loadInitial<T>({
    required PaginatedListState<T> current,
    required PaginatedFetch<T> fetch,
    required int limit,
  }) async {
    if (current.userId.isEmpty) return current;

    final loading = current.copyWith(
      status: PaginatedStatus.loading,
      items: [],
      meta: null,
      clearError: true,
    );

    try {
      final page = await fetch(current.userId, 1, limit);
      return loading.copyWith(
        status: PaginatedStatus.loaded,
        items: page.items,
        meta: PaginationMeta.fromPage(page),
        hasLoadedOnce: true,
      );
    } catch (e) {
      return loading.copyWith(
        status: PaginatedStatus.error,
        errorMessage: e.toString(),
        hasLoadedOnce: true,
      );
    }
  }

  static Future<PaginatedListState<T>> loadMore<T>({
    required PaginatedListState<T> current,
    required PaginatedFetch<T> fetch,
    required int limit,
  }) async {
    if (current.userId.isEmpty ||
        current.hasReachedMax ||
        current.isLoadingMore ||
        current.isLoading) {
      return current;
    }

    final loadingMore = current.copyWith(status: PaginatedStatus.loadingMore);

    try {
      final nextPage = (current.meta?.page ?? 0) + 1;
      final page = await fetch(current.userId, nextPage, limit);
      return loadingMore.copyWith(
        status: PaginatedStatus.loaded,
        items: [...current.items, ...page.items],
        meta: PaginationMeta.fromPage(page),
      );
    } catch (_) {
      return loadingMore.copyWith(status: PaginatedStatus.loaded);
    }
  }
}
