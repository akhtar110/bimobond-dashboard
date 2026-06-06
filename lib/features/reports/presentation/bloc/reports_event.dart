part of 'reports_bloc.dart';

sealed class ReportsEvent {}

/// Initial / hard load — resets page to 1 and replaces existing list.
class LoadReportsEvent extends ReportsEvent {}

/// Append next page to the existing list.
class LoadMoreReportsEvent extends ReportsEvent {}

/// Switch status/type filter and reload from page 1.
class FilterReportsEvent extends ReportsEvent {
  FilterReportsEvent({this.status, this.type});
  final String? status; // PENDING | RESOLVED | DISMISSED | null = all
  final String? type;   // post | user | comment | null = all
}

/// Reload with the same filters (e.g. after a status update).
class RefreshReportsEvent extends ReportsEvent {}

class UpdateReportStatusEvent extends ReportsEvent {
  UpdateReportStatusEvent({required this.reportId, required this.status});
  final String reportId;
  final String status; // RESOLVED | DISMISSED | PENDING
}

/// Tap on a report card — resolve the routing target and emit a
/// [ReportsNavigation] side-effect so the page can navigate.
class OpenReportTargetEvent extends ReportsEvent {
  OpenReportTargetEvent(this.report);
  final ReportEntity report;
}

/// Consumed by the BlocListener after navigation has started;
/// clears [ReportsLoaded.pendingNavigation] to prevent re-firing.
class ClearNavigationEvent extends ReportsEvent {}
