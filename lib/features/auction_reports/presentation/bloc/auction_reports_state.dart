part of 'auction_reports_bloc.dart';

abstract class AuctionReportsState {}

class AuctionReportsInitial extends AuctionReportsState {}

class AuctionReportsLoading extends AuctionReportsState {}

class AuctionReportsLoaded extends AuctionReportsState {
  AuctionReportsLoaded({
    required this.auctions,
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

  final List<AuctionReportListItem> auctions;
  final int currentPage;
  final int lastPage;
  final int total;
  final AuctionReportsListQuery query;
  final String searchQuery;
  final bool isFetching;
  final AuctionReportOverviewEntity? overview;
  final bool isOverviewLoading;
  final int overviewDays;

  AuctionReportsLoaded copyWith({
    List<AuctionReportListItem>? auctions,
    int? currentPage,
    int? lastPage,
    int? total,
    AuctionReportsListQuery? query,
    String? searchQuery,
    bool? isFetching,
    AuctionReportOverviewEntity? overview,
    bool? isOverviewLoading,
    int? overviewDays,
    bool clearOverview = false,
  }) {
    return AuctionReportsLoaded(
      auctions: auctions ?? this.auctions,
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

class AuctionReportsError extends AuctionReportsState {
  AuctionReportsError(this.message);
  final String message;
}
