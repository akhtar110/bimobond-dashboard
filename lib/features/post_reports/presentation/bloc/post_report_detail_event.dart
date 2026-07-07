part of 'post_report_detail_bloc.dart';

abstract class PostReportDetailEvent {}

class LoadPostReportDetailEvent extends PostReportDetailEvent {
  LoadPostReportDetailEvent({required this.postId, this.days = 30});
  final String postId;
  final int days;
}

class ChangePostReportDetailDaysEvent extends PostReportDetailEvent {
  ChangePostReportDetailDaysEvent(this.days);
  final int days;
}

class RefreshPostReportDetailEvent extends PostReportDetailEvent {}
