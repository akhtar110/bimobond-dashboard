import 'package:equatable/equatable.dart';

class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasReachedMax => page >= totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

class PaginatedResult<T> extends Equatable {
  const PaginatedResult({
    required this.data,
    required this.meta,
  });

  final List<T> data;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}
