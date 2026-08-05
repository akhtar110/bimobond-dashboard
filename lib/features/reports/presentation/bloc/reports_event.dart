part of 'reports_bloc.dart';

sealed class ReportsEvent {}

/// Initial / hard load — resets page to 1 and replaces existing list.
class LoadReportsEvent extends ReportsEvent {}

/// Append next page to the existing list.
class LoadMoreReportsEvent extends ReportsEvent {}

/// Jump to a specific page and replace the list (desktop pagination).
class GoToReportsPageEvent extends ReportsEvent {
  GoToReportsPageEvent(this.page);
  final int page;
}

class FilterReportsEvent extends ReportsEvent {
  FilterReportsEvent({
    this.status,
    this.type,
    this.reporterId,
    this.reportedUserId,
    this.postId,
    this.commentId,
    this.storyId,
    this.search,
    this.startDate,
    this.endDate,
    this.sortBy,
    this.sortOrder,
    this.clearAdvanced = false,
    this.resetStatus = false,
    this.resetType = false,
  });

  final String? status;
  final String? type;
  final String? reporterId;
  final String? reportedUserId;
  final String? postId;
  final String? commentId;
  final String? storyId;
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder;
  final bool clearAdvanced;
  final bool resetStatus;
  final bool resetType;
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
