part of 'auction_report_detail_bloc.dart';

abstract class AuctionReportDetailEvent {}

class LoadAuctionReportDetailEvent extends AuctionReportDetailEvent {
  LoadAuctionReportDetailEvent({required this.auctionId, this.days = 30});
  final String auctionId;
  final int days;
}

class ChangeAuctionReportDetailDaysEvent extends AuctionReportDetailEvent {
  ChangeAuctionReportDetailDaysEvent(this.days);
  final int days;
}

class RefreshAuctionReportDetailEvent extends AuctionReportDetailEvent {}
