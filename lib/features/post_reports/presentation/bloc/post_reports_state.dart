part of 'post_reports_bloc.dart';

abstract class PostReportsState {}

class PostReportsInitial extends PostReportsState {}

class PostReportsLoading extends PostReportsState {}

class PostReportsLoaded extends PostReportsState {
  PostReportsLoaded({
    required this.posts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.query,
    this.searchQuery = '',
    this.isFetching = false,
    this.overview,
    this.isOverviewLoading = false,
    this.overviewDays = 30,
  });

  final List<PostReportListItem> posts;
  final int currentPage;
  final int lastPage;
  final int total;
  final PostReportsListQuery query;
  final String searchQuery;
  final bool isFetching;
  final PostReportOverviewEntity? overview;
  final bool isOverviewLoading;
  final int overviewDays;

  PostReportsLoaded copyWith({
    List<PostReportListItem>? posts,
    int? currentPage,
    int? lastPage,
    int? total,
    PostReportsListQuery? query,
    String? searchQuery,
    bool? isFetching,
    PostReportOverviewEntity? overview,
    bool? isOverviewLoading,
    int? overviewDays,
    bool clearOverview = false,
  }) {
    return PostReportsLoaded(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      query: query ?? this.query,
      searchQuery: searchQuery ?? this.searchQuery,
      isFetching: isFetching ?? this.isFetching,
      overview: clearOverview ? null : (overview ?? this.overview),
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      overviewDays: overviewDays ?? this.overviewDays,
    );
  }
}

class PostReportsError extends PostReportsState {
  PostReportsError(this.message);
  final String message;
}
