part of 'category_reports_bloc.dart';

sealed class CategoryReportsEvent {}

class LoadCategoryReportsOverviewEvent extends CategoryReportsEvent {}

class LoadCategoryReportsListEvent extends CategoryReportsEvent {
  LoadCategoryReportsListEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class GoToCategoryReportsPageEvent extends CategoryReportsEvent {
  GoToCategoryReportsPageEvent(this.page);
  final int page;
}

class LoadMoreCategoryReportsEvent extends CategoryReportsEvent {}

class UpdateCategoryReportsSearchEvent extends CategoryReportsEvent {
  UpdateCategoryReportsSearchEvent(this.query);
  final String query;
}

class UpdateCategoryReportsSortEvent extends CategoryReportsEvent {
  UpdateCategoryReportsSortEvent(this.sort);
  final CategoryReportsSort sort;
}

class UpdateCategoryReportsActiveFilterEvent extends CategoryReportsEvent {
  UpdateCategoryReportsActiveFilterEvent(this.isActive);
  final bool? isActive;
}

class UpdateCategoryReportsMainFilterEvent extends CategoryReportsEvent {
  UpdateCategoryReportsMainFilterEvent(this.isMain);
  final bool? isMain;
}

class UpdateCategoryReportsParentFilterEvent extends CategoryReportsEvent {
  UpdateCategoryReportsParentFilterEvent(this.parentId);
  final String? parentId;
}

class ChangeCategoryReportsDaysEvent extends CategoryReportsEvent {
  ChangeCategoryReportsDaysEvent(this.days);
  final int days;
}

class RefreshCategoryReportsEvent extends CategoryReportsEvent {}
