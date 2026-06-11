part of 'category_report_detail_bloc.dart';

sealed class CategoryReportDetailState {}

class CategoryReportDetailInitial extends CategoryReportDetailState {}

class CategoryReportDetailLoading extends CategoryReportDetailState {}

class CategoryReportDetailLoaded extends CategoryReportDetailState {
  CategoryReportDetailLoaded({
    required this.detail,
    required this.days,
    this.isRefreshing = false,
  });

  final CategoryReportDetailEntity detail;
  final int days;
  final bool isRefreshing;

  CategoryReportDetailLoaded copyWith({
    CategoryReportDetailEntity? detail,
    int? days,
    bool? isRefreshing,
  }) {
    return CategoryReportDetailLoaded(
      detail: detail ?? this.detail,
      days: days ?? this.days,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class CategoryReportDetailError extends CategoryReportDetailState {
  CategoryReportDetailError(this.message);
  final String message;
}
