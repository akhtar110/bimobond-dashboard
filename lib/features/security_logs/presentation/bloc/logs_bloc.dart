import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/log_entity.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../utils/logs_export_service.dart';
import 'logs_event.dart';
import 'logs_state.dart';

class LogsBloc extends Bloc<LogsEvent, LogsState> {
  LogsBloc({required GetLogsUseCase getLogs})
      : _getLogs = getLogs,
        super(const LogsInitial()) {
    on<LoadLogsEvent>(_onLoad);
    on<RefreshLogsEvent>(_onRefresh);
    on<LogsPageChangedEvent>(_onPageChanged);
    on<LogsLimitChangedEvent>(_onLimitChanged);
    on<LogsUserChangedEvent>(_onUserChanged);
    on<LogsActorRoleChangedEvent>(_onActorRoleChanged);
    on<LogsCategoryChangedEvent>(_onCategoryChanged);
    on<LogsActionChangedEvent>(_onActionChanged);
    on<LogsApplyFiltersEvent>(_onApplyFilters);
    on<LogsResetFiltersEvent>(_onResetFilters);
    on<ClearLogsMessageEvent>(_onClearMessage);
    on<ExportLogsEvent>(_onExportLogs);
    on<ClearLogsExportMessageEvent>(_onClearExportMessage);
  }

  final GetLogsUseCase _getLogs;
  LogsQuery _query = const LogsQuery();

  Future<void> _onLoad(LoadLogsEvent event, Emitter<LogsState> emit) async {
    if (event.page != null) {
      _query = _query.copyWith(page: event.page);
    }

    final current = state;
    final LogsLoaded? previous = current is LogsLoaded ? current : null;
    if (previous == null) {
      emit(const LogsLoading());
    } else {
      emit(previous.copyWith(isRefreshing: true, clearMessages: true));
    }

    try {
      final result = await _getLogs(_query);
      emit(
        LogsLoaded(
          logs: result.data,
          meta: result.meta,
          query: _query,
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (previous != null) {
        emit(
          previous.copyWith(
            isRefreshing: false,
            isPaginating: false,
            errorMessage: message,
          ),
        );
      } else {
        emit(LogsError(message));
      }
    }
  }

  Future<void> _onRefresh(
    RefreshLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    add(LoadLogsEvent(page: _query.page));
  }

  Future<void> _onPageChanged(
    LogsPageChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    if (_query.page == event.page) return;
    final current = state;
    if (current is LogsLoaded) {
      emit(current.copyWith(isPaginating: true, clearMessages: true));
    }
    _query = _query.copyWith(page: event.page);
    add(const LoadLogsEvent());
  }

  Future<void> _onLimitChanged(
    LogsLimitChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    if (_query.limit == event.limit) return;
    _query = _query.copyWith(page: 1, limit: event.limit);
    add(const LoadLogsEvent());
  }

  Future<void> _onUserChanged(
    LogsUserChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    final user = event.user;
    final userId = user?.id.trim();
    _query = _query.copyWith(
      page: 1,
      user: user,
      userId: userId,
      clearUser: user == null || userId == null || userId.isEmpty,
    );
    add(const LoadLogsEvent());
  }

  Future<void> _onActorRoleChanged(
    LogsActorRoleChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    final role = _normalizeActorRole(event.actorRole);
    _query = _query.copyWith(
      page: 1,
      actorRole: role,
      clearActorRole: role == null,
    );
    add(const LoadLogsEvent());
  }

  Future<void> _onCategoryChanged(
    LogsCategoryChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    final category = _normalizeCategory(event.category);
    final action = _query.action;
    final isBanAction = action == 'USER_BAN';
    final actionStillValid = action == null ||
        category == null ||
        LogsQuery.actionsForCategory(category).contains(action) ||
        (isBanAction &&
            (category == 'ADMIN' || category == 'MODERATION'));
    _query = _query.copyWith(
      page: 1,
      category: category,
      clearCategory: category == null,
      clearAction: !actionStillValid,
    );
    add(const LoadLogsEvent());
  }

  Future<void> _onActionChanged(
    LogsActionChangedEvent event,
    Emitter<LogsState> emit,
  ) async {
    final action = _normalizeAction(event.action);
    final isBanAction = action == 'USER_BAN';
    _query = _query.copyWith(
      page: 1,
      action: action,
      clearAction: action == null,
      // Ban/Unban → `?action=USER_BAN` only (no category).
      clearCategory: isBanAction,
    );
    add(const LoadLogsEvent());
  }

  Future<void> _onApplyFilters(
    LogsApplyFiltersEvent event,
    Emitter<LogsState> emit,
  ) async {
    final user = event.user;
    final userId = (user?.id ?? event.userId)?.trim();
    var category = _normalizeCategory(event.category);
    var action = _normalizeAction(event.action);

    final isBanAction = action == 'USER_BAN';
    if (action != null &&
        category != null &&
        !isBanAction &&
        !LogsQuery.actionsForCategory(category).contains(action)) {
      action = null;
    }
    // Ban + Unban logs: `GET /user-history/admin/logs?action=USER_BAN`
    if (isBanAction) {
      category = null;
    }

    _query = LogsQuery(
      page: 1,
      limit: event.limit ?? _query.limit,
      user: user,
      userId: (userId == null || userId.isEmpty) ? null : userId,
      actorRole: _normalizeActorRole(event.actorRole),
      category: category,
      action: action,
      from: event.from,
      to: event.to,
    );
    add(const LoadLogsEvent());
  }

  Future<void> _onResetFilters(
    LogsResetFiltersEvent event,
    Emitter<LogsState> emit,
  ) async {
    _query = LogsQuery(limit: _query.limit);
    add(const LoadLogsEvent());
  }

  void _onClearMessage(
    ClearLogsMessageEvent event,
    Emitter<LogsState> emit,
  ) {
    final current = state;
    if (current is LogsLoaded) {
      emit(current.copyWith(clearMessages: true));
    }
  }

  Future<void> _onExportLogs(
    ExportLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    final current = state;
    if (current is! LogsLoaded || current.isExporting) return;

    emit(current.copyWith(isExporting: true, clearExportMessage: true));

    try {
      // Build an export query using current filters but a larger page size
      // to efficiently fetch all matching records.
      final exportQuery = _query.copyWith(page: 1, limit: 100);

      final allLogs = <LogEntity>[];
      final seenIds = <String>{};

      int page = 1;
      int totalPages = 1;

      do {
        final res = await _getLogs(exportQuery.copyWith(page: page));
        for (final log in res.data) {
          if (seenIds.add(log.id)) {
            allLogs.add(log);
          }
        }
        totalPages = res.meta.totalPages < 1 ? 1 : res.meta.totalPages;
        page++;
      } while (page <= totalPages && page <= 50); // safety cap: max 5 000 rows

      final exportList = allLogs.isNotEmpty ? allLogs : current.logs;

      final params = LogsExportParams(
        logs: exportList,
        query: _query,
      );

      await LogsExportService.exportLogs(
        params: params,
        format: event.format,
      );

      final latest = state;
      if (latest is LogsLoaded) {
        emit(
          latest.copyWith(
            isExporting: false,
            exportMessage:
                'Export generated successfully (${exportList.length} records)',
            exportIsError: false,
          ),
        );
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final latest = state;
      if (latest is LogsLoaded) {
        emit(
          latest.copyWith(
            isExporting: false,
            exportMessage: 'Export failed: $message',
            exportIsError: true,
          ),
        );
      }
    }
  }

  void _onClearExportMessage(
    ClearLogsExportMessageEvent event,
    Emitter<LogsState> emit,
  ) {
    final current = state;
    if (current is LogsLoaded) {
      emit(current.copyWith(clearExportMessage: true));
    }
  }

  String? _normalizeActorRole(String? value) {
    final role = value?.trim().toUpperCase();
    if (role == null || role.isEmpty) return null;
    if (!LogsQuery.actorRoleOptions.contains(role)) return null;
    return role;
  }

  String? _normalizeCategory(String? value) {
    final category = value?.trim().toUpperCase();
    if (category == null || category.isEmpty) return null;
    if (!LogsQuery.categoryOptions.contains(category)) return null;
    return category;
  }

  String? _normalizeAction(String? value) {
    final action = value?.trim().toUpperCase();
    if (action == null || action.isEmpty) return null;
    return switch (action) {
      'BAN' ||
      'BAN_USER' ||
      'UNBAN' ||
      'UNBAN_USER' ||
      'USER_UNBAN' =>
        'USER_BAN',
      _ => action,
    };
  }
}

