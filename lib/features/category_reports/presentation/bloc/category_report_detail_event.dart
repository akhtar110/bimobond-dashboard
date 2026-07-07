part of 'category_report_detail_bloc.dart';

sealed class CategoryReportDetailEvent {}

class LoadCategoryReportDetailEvent extends CategoryReportDetailEvent {
  LoadCategoryReportDetailEvent({required this.categoryId, this.days = 30});
  final String categoryId;
  final int days;
}

class ChangeCategoryReportDetailDaysEvent extends CategoryReportDetailEvent {
  ChangeCategoryReportDetailDaysEvent(this.days);
  final int days;
}

class RefreshCategoryReportDetailEvent extends CategoryReportDetailEvent {}
