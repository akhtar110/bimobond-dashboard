import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bimo_bond_dashboard/features/promotions/domain/entities/pagination_meta.dart';
import '../../../security_logs/domain/entities/log_entity.dart';
import '../../../security_logs/domain/usecases/get_logs_usecase.dart';

// EVENTS
abstract class UserAuditLogEvent extends Equatable {
  const UserAuditLogEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserAuditLogEvent extends UserAuditLogEvent {
  const LoadUserAuditLogEvent({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

class RefreshUserAuditLogEvent extends UserAuditLogEvent {
  const RefreshUserAuditLogEvent();
}

// STATES
abstract class UserAuditLogState extends Equatable {
  const UserAuditLogState();

  @override
  List<Object?> get props => [];
}

class UserAuditLogInitial extends UserAuditLogState {
  const UserAuditLogInitial();
}

class UserAuditLogLoading extends UserAuditLogState {
  const UserAuditLogLoading();
}

class UserAuditLogLoaded extends UserAuditLogState {
  const UserAuditLogLoaded({
    required this.logs,
    required this.meta,
    this.isRefreshing = false,
  });

  final List<LogEntity> logs;
  final PaginationMeta meta;
  final bool isRefreshing;

  UserAuditLogLoaded copyWith({
    List<LogEntity>? logs,
    PaginationMeta? meta,
    bool? isRefreshing,
  }) {
    return UserAuditLogLoaded(
      logs: logs ?? this.logs,
      meta: meta ?? this.meta,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [logs, meta, isRefreshing];
}

class UserAuditLogError extends UserAuditLogState {
  const UserAuditLogError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// BLOC
class UserAuditLogBloc extends Bloc<UserAuditLogEvent, UserAuditLogState> {
  UserAuditLogBloc({
    required String userId,
    required GetLogsUseCase getLogs,
  })  : _userId = userId,
        _getLogs = getLogs,
        super(const UserAuditLogInitial()) {
    on<LoadUserAuditLogEvent>(_onLoad);
    on<RefreshUserAuditLogEvent>(_onRefresh);
  }

  final String _userId;
  final GetLogsUseCase _getLogs;
  int _currentPage = 1;
  static const int _limit = 15;

  Future<void> _onLoad(
    LoadUserAuditLogEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    if (event.page != null) {
      _currentPage = event.page!;
    }

    final current = state;
    final UserAuditLogLoaded? previous =
        current is UserAuditLogLoaded ? current : null;

    if (previous == null) {
      emit(const UserAuditLogLoading());
    } else {
      emit(previous.copyWith(isRefreshing: true));
    }

    try {
      final query = LogsQuery(
        userId: _userId,
        page: _currentPage,
        limit: _limit,
      );
      final result = await _getLogs(query);
      emit(
        UserAuditLogLoaded(
          logs: result.data,
          meta: result.meta,
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (previous != null) {
        emit(previous.copyWith(isRefreshing: false));
      } else {
        emit(UserAuditLogError(message));
      }
    }
  }

  Future<void> _onRefresh(
    RefreshUserAuditLogEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    add(LoadUserAuditLogEvent(page: _currentPage));
  }
}
