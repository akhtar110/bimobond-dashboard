part of 'gift_reports_bloc.dart';

sealed class GiftReportsState {}

class GiftReportsInitial extends GiftReportsState {}

class GiftReportsLoading extends GiftReportsState {}

class GiftReportsLoaded extends GiftReportsState {
  GiftReportsLoaded({
    this.overview,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.days,
    this.searchQuery = '',
    this.sort = GiftReportsSort.newest,
    this.isActiveFilter,
    this.fromDate,
    this.toDate,
    this.minPriceFilter,
    this.maxPriceFilter,
    this.isOverviewLoading = false,
    this.isListFetching = false,
    this.isListLoadingMore = false,
    this.overviewError,
    this.listError,
  });

  final GiftReportOverviewEntity? overview;
  final List<GiftReportListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int days;
  final String searchQuery;
  final GiftReportsSort sort;
  final bool? isActiveFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minPriceFilter;
  final double? maxPriceFilter;
  final bool isOverviewLoading;
  final bool isListFetching;
  final bool isListLoadingMore;
  final String? overviewError;
  final String? listError;

  bool get hasReachedMax => currentPage >= lastPage;

  GiftReportsLoaded copyWith({
    GiftReportOverviewEntity? overview,
    List<GiftReportListItemEntity>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    int? days,
    String? searchQuery,
    GiftReportsSort? sort,
    bool? isActiveFilter,
    bool clearActiveFilter = false,
    bool setDateRange = false,
    DateTime? fromDate,
    DateTime? toDate,
    bool setPriceRange = false,
    double? minPriceFilter,
    double? maxPriceFilter,
    bool? isOverviewLoading,
    bool? isListFetching,
    bool? isListLoadingMore,
    String? overviewError,
    String? listError,
    bool clearOverviewError = false,
    bool clearListError = false,
  }) {
    return GiftReportsLoaded(
      overview: overview ?? this.overview,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      days: days ?? this.days,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      isActiveFilter:
          clearActiveFilter ? null : (isActiveFilter ?? this.isActiveFilter),
      fromDate: setDateRange ? fromDate : (fromDate ?? this.fromDate),
      toDate: setDateRange ? toDate : (toDate ?? this.toDate),
      minPriceFilter: setPriceRange
          ? minPriceFilter
          : (minPriceFilter ?? this.minPriceFilter),
      maxPriceFilter: setPriceRange
          ? maxPriceFilter
          : (maxPriceFilter ?? this.maxPriceFilter),
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      isListFetching: isListFetching ?? this.isListFetching,
      isListLoadingMore: isListLoadingMore ?? this.isListLoadingMore,
      overviewError:
          clearOverviewError ? null : (overviewError ?? this.overviewError),
      listError: clearListError ? null : (listError ?? this.listError),
    );
  }
}

class GiftReportsError extends GiftReportsState {
  GiftReportsError(this.message);
  final String message;
}
