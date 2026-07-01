part of 'post_reports_bloc.dart';

abstract class PostReportsEvent {}

class LoadPostReportsEvent extends PostReportsEvent {
  LoadPostReportsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class GoToPostReportsPageEvent extends PostReportsEvent {
  GoToPostReportsPageEvent(this.page);
  final int page;
}

class LoadMorePostReportsEvent extends PostReportsEvent {}

class UpdatePostReportsSearchEvent extends PostReportsEvent {
  UpdatePostReportsSearchEvent(this.query);
  final String query;
}

class UpdatePostReportsFiltersEvent extends PostReportsEvent {
  UpdatePostReportsFiltersEvent(this.query);
  final PostReportsListQuery query;
}

class UpdatePostReportsSortEvent extends PostReportsEvent {
  UpdatePostReportsSortEvent(this.sort);
  final PostReportsSortOrder sort;
}

class ClearPostReportsFiltersEvent extends PostReportsEvent {}

class LoadPostReportsOverviewEvent extends PostReportsEvent {
  LoadPostReportsOverviewEvent({this.days = 30});
  final int days;
}
