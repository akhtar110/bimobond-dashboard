import '../../domain/entities/pagination_meta.dart';

enum PaginatedStatus { initial, loading, loaded, loadingMore, error }

class PaginatedListState<T> {
  const PaginatedListState({
    this.status = PaginatedStatus.initial,
    this.userId = '',
    this.items = const [],
    this.meta,
    this.errorMessage,
    this.hasLoadedOnce = false,
  });

  final PaginatedStatus status;
  final String userId;
  final List<T> items;
  final PaginationMeta? meta;
  final String? errorMessage;
  final bool hasLoadedOnce;

  bool get isLoading => status == PaginatedStatus.loading;
  bool get isLoadingMore => status == PaginatedStatus.loadingMore;
  bool get hasError => status == PaginatedStatus.error;
  bool get hasReachedMax => meta?.hasReachedMax ?? true;

  PaginatedListState<T> copyWith({
    PaginatedStatus? status,
    String? userId,
    List<T>? items,
    PaginationMeta? meta,
    String? errorMessage,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return PaginatedListState<T>(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
