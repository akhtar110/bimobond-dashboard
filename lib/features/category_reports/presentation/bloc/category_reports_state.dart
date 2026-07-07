part of 'category_reports_bloc.dart';

sealed class CategoryReportsState {}

class CategoryReportsInitial extends CategoryReportsState {}

class CategoryReportsLoading extends CategoryReportsState {}

class CategoryReportsLoaded extends CategoryReportsState {
  CategoryReportsLoaded({
    this.overview,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.days,
    this.searchQuery = '',
    this.sort = CategoryReportsSort.order,
    this.isActiveFilter,
    this.isMainFilter,
    this.parentIdFilter,
    this.mainCategoryOptions = const [],
    this.isOverviewLoading = false,
    this.isListFetching = false,
    this.isListLoadingMore = false,
    this.overviewError,
    this.listError,
  });

  final CategoryReportOverviewEntity? overview;
  final List<CategoryReportListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int days;
  final String searchQuery;
  final CategoryReportsSort sort;
  final bool? isActiveFilter;
  final bool? isMainFilter;
  final String? parentIdFilter;
  final List<CategoryReportFilterOption> mainCategoryOptions;
  final bool isOverviewLoading;
  final bool isListFetching;
  final bool isListLoadingMore;
  final String? overviewError;
  final String? listError;

  bool get hasReachedMax => currentPage >= lastPage;

  CategoryReportsLoaded copyWith({
    CategoryReportOverviewEntity? overview,
    List<CategoryReportListItemEntity>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    int? days,
    String? searchQuery,
    CategoryReportsSort? sort,
    bool? isActiveFilter,
    bool clearActiveFilter = false,
    bool? isMainFilter,
    bool clearMainFilter = false,
    String? parentIdFilter,
    bool clearParentFilter = false,
    List<CategoryReportFilterOption>? mainCategoryOptions,
    bool? isOverviewLoading,
    bool? isListFetching,
    bool? isListLoadingMore,
    String? overviewError,
    String? listError,
    bool clearOverviewError = false,
    bool clearListError = false,
  }) {
    return CategoryReportsLoaded(
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
      isMainFilter:
          clearMainFilter ? null : (isMainFilter ?? this.isMainFilter),
      parentIdFilter: clearParentFilter
          ? null
          : (parentIdFilter ?? this.parentIdFilter),
      mainCategoryOptions: mainCategoryOptions ?? this.mainCategoryOptions,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      isListFetching: isListFetching ?? this.isListFetching,
      isListLoadingMore: isListLoadingMore ?? this.isListLoadingMore,
      overviewError:
          clearOverviewError ? null : (overviewError ?? this.overviewError),
      listError: clearListError ? null : (listError ?? this.listError),
    );
  }
}

class CategoryReportsError extends CategoryReportsState {
  CategoryReportsError(this.message);
  final String message;
}
