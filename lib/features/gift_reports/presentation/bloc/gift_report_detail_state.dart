part of 'gift_report_detail_bloc.dart';

sealed class GiftReportDetailState {}

class GiftReportDetailInitial extends GiftReportDetailState {}

class GiftReportDetailLoading extends GiftReportDetailState {}

class GiftReportDetailLoaded extends GiftReportDetailState {
  GiftReportDetailLoaded({
    required this.detail,
    required this.days,
    this.isRefreshing = false,
  });

  final GiftReportDetailEntity detail;
  final int days;
  final bool isRefreshing;

  GiftReportDetailLoaded copyWith({
    GiftReportDetailEntity? detail,
    int? days,
    bool? isRefreshing,
  }) {
    return GiftReportDetailLoaded(
      detail: detail ?? this.detail,
      days: days ?? this.days,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class GiftReportDetailError extends GiftReportDetailState {
  GiftReportDetailError(this.message);
  final String message;
}
