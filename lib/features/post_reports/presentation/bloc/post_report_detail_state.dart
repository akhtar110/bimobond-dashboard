part of 'post_report_detail_bloc.dart';

abstract class PostReportDetailState {}

class PostReportDetailInitial extends PostReportDetailState {}

class PostReportDetailLoading extends PostReportDetailState {}

class PostReportDetailLoaded extends PostReportDetailState {
  PostReportDetailLoaded({
    required this.detail,
    required this.days,
    this.isRefreshing = false,
  });

  final PostReportDetailEntity detail;
  final int days;
  final bool isRefreshing;

  PostReportDetailLoaded copyWith({
    PostReportDetailEntity? detail,
    int? days,
    bool? isRefreshing,
  }) {
    return PostReportDetailLoaded(
      detail: detail ?? this.detail,
      days: days ?? this.days,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class PostReportDetailError extends PostReportDetailState {
  PostReportDetailError(this.message);
  final String message;
}
