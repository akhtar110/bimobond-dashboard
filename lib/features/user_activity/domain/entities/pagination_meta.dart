import 'paginated_page.dart';

class PaginationMeta {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.lastPage,
  });

  final int total;
  final int page;
  final int lastPage;

  bool get hasReachedMax => page >= lastPage;

  factory PaginationMeta.fromPage(PaginatedPage<dynamic> page) {
    return PaginationMeta(
      total: page.total,
      page: page.page,
      lastPage: page.lastPage,
    );
  }
}

/// Alias for paginated API responses.
typedef PaginatedResponse<T> = PaginatedPage<T>;
