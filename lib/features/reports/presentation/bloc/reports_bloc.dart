import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/update_report_status_usecase.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required GetReports getReports,
    required UpdateReportStatus updateReportStatus,
  })  : _getReports = getReports,
        _updateStatus = updateReportStatus,
        super(ReportsInitial()) {
    on<LoadReportsEvent>(_onLoad);
    on<LoadMoreReportsEvent>(_onLoadMore);
    on<FilterReportsEvent>(_onFilter);
    on<RefreshReportsEvent>(_onRefresh);
    on<UpdateReportStatusEvent>(_onUpdateStatus);
    on<OpenReportTargetEvent>(_onOpenTarget);
    on<ClearNavigationEvent>(_onClearNavigation);
  }

  final GetReports _getReports;
  final UpdateReportStatus _updateStatus;

  static const _limit = 15;

  // ── helpers ────────────────────────────────────────────────────────────────

  ReportsLoaded? get _loaded => state is ReportsLoaded ? state as ReportsLoaded : null;

  // ── handlers ───────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    await _fetch(emit, page: 1, replace: true);
  }

  Future<void> _onLoadMore(
    LoadMoreReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final current = _loaded;
    if (current == null || current.hasReachedMax || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    await _fetch(emit, page: current.currentPage + 1, replace: false);
  }

  Future<void> _onFilter(
    FilterReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    await _fetch(
      emit,
      page: 1,
      replace: true,
      statusFilter: event.status,
      typeFilter: event.type,
    );
  }

  Future<void> _onRefresh(
    RefreshReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final current = _loaded;
    final statusFilter = current?.statusFilter;
    final typeFilter = current?.typeFilter;
    emit(ReportsLoading());
    await _fetch(
      emit,
      page: 1,
      replace: true,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
    );
  }

  Future<void> _onUpdateStatus(
    UpdateReportStatusEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final current = _loaded;
    if (current == null) return;

    // Optimistic update — replace the single item immediately.
    final optimistic = current.reports
        .map((r) => r.id == event.reportId ? r.copyWith(status: event.status) : r)
        .toList();
    emit(current.copyWith(reports: optimistic, updatingId: event.reportId));

    try {
      final updated = await _updateStatus(
        id: event.reportId,
        status: event.status,
      );
      final confirmed = current.reports
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      emit(current.copyWith(reports: confirmed, clearUpdatingId: true));
    } catch (e) {
      // Roll back and surface the error via a one-shot message.
      emit(current.copyWith(
        reports: current.reports,
        clearUpdatingId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _onOpenTarget(
    OpenReportTargetEvent event,
    Emitter<ReportsState> emit,
  ) {
    final current = _loaded;
    if (current == null) return;

    final report = event.report;
    ReportsNavigation? nav;

    final postId = report.postId ?? report.post?.id;
    if (postId != null && postId.isNotEmpty) {
      nav = NavigateToPost(
        postId: postId,
        commentId: report.commentId,
        authorUserId: report.postAuthorUserId,
        authorUsername: report.postAuthor?.username,
        authorFullName: report.postAuthor?.fullName,
        authorAvatarUrl: report.postAuthor?.avatarUrl,
      );
    } else if (report.reportedUserId != null) {
      nav = NavigateToUser(
        userId: report.reportedUserId!,
        username: report.reportedUser?.username,
        fullName: report.reportedUser?.fullName,
        avatarUrl: report.reportedUser?.avatarUrl,
      );
    }

    if (nav != null) {
      emit(current.copyWith(pendingNavigation: nav));
    }
  }

  void _onClearNavigation(
    ClearNavigationEvent event,
    Emitter<ReportsState> emit,
  ) {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(clearNavigation: true));
  }

  // ── core fetch helper ──────────────────────────────────────────────────────

  Future<void> _fetch(
    Emitter<ReportsState> emit, {
    required int page,
    required bool replace,
    String? statusFilter,
    String? typeFilter,
  }) async {
    try {
      final result = await _getReports(
        page: page,
        limit: _limit,
        status: statusFilter,
        type: typeFilter,
      );

      final prev = _loaded;
      final merged = replace
          ? result.reports
          : <ReportEntity>[...(prev?.reports ?? []), ...result.reports];

      emit(ReportsLoaded(
        reports: merged,
        currentPage: page,
        lastPage: result.lastPage,
        total: result.total,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(ReportsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
