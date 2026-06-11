part of 'auction_reports_bloc.dart';

abstract class AuctionReportsEvent {}

class LoadAuctionReportsEvent extends AuctionReportsEvent {
  LoadAuctionReportsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class GoToAuctionReportsPageEvent extends AuctionReportsEvent {
  GoToAuctionReportsPageEvent(this.page);
  final int page;
}

class UpdateAuctionReportsSearchEvent extends AuctionReportsEvent {
  UpdateAuctionReportsSearchEvent(this.query);
  final String query;
}

class UpdateAuctionReportsFiltersEvent extends AuctionReportsEvent {
  UpdateAuctionReportsFiltersEvent(this.query);
  final AuctionReportsListQuery query;
}

class UpdateAuctionReportsSortEvent extends AuctionReportsEvent {
  UpdateAuctionReportsSortEvent(this.sort);
  final AuctionReportsSortOrder sort;
}

class ClearAuctionReportsFiltersEvent extends AuctionReportsEvent {}

class LoadAuctionReportsOverviewEvent extends AuctionReportsEvent {
  LoadAuctionReportsOverviewEvent({this.days = 30});
  final int days;
}
