part of 'auction_report_detail_bloc.dart';

abstract class AuctionReportDetailState {}

class AuctionReportDetailInitial extends AuctionReportDetailState {}

class AuctionReportDetailLoading extends AuctionReportDetailState {}

class AuctionReportDetailLoaded extends AuctionReportDetailState {
  AuctionReportDetailLoaded({
    required this.detail,
    required this.days,
    this.isRefreshing = false,
  });

  final AuctionReportDetailEntity detail;
  final int days;
  final bool isRefreshing;

  AuctionReportDetailLoaded copyWith({
    AuctionReportDetailEntity? detail,
    int? days,
    bool? isRefreshing,
  }) {
    return AuctionReportDetailLoaded(
      detail: detail ?? this.detail,
      days: days ?? this.days,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class AuctionReportDetailError extends AuctionReportDetailState {
  AuctionReportDetailError(this.message);
  final String message;
}
