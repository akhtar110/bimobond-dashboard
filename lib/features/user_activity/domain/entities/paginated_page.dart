class PaginatedPage<T> {
  const PaginatedPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int lastPage;
  final int total;

  bool get hasReachedMax => page >= lastPage;
}
