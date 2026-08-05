import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bimo_bond_dashboard/features/promotions/domain/entities/pagination_meta.dart';
import '../../../security_logs/data/datasources/user_audit_log_socket_service.dart';
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

class StartRealtimeAuditLogListening extends UserAuditLogEvent {
  const StartRealtimeAuditLogListening({this.intervalSeconds = 5});

  final int intervalSeconds;

  @override
  List<Object?> get props => [intervalSeconds];
}

class StopRealtimeAuditLogListening extends UserAuditLogEvent {
  const StopRealtimeAuditLogListening();
}

class PollRealtimeAuditLogEvent extends UserAuditLogEvent {
  const PollRealtimeAuditLogEvent();
}

class RealtimeLogReceivedEvent extends UserAuditLogEvent {
  const RealtimeLogReceivedEvent(this.log);

  final LogEntity log;

  @override
  List<Object?> get props => [log];
}

class SocketStatusChangedEvent extends UserAuditLogEvent {
  const SocketStatusChangedEvent(this.status);

  final RealtimeSocketStatus status;

  @override
  List<Object?> get props => [status];
}

class ReconnectSocketEvent extends UserAuditLogEvent {
  const ReconnectSocketEvent();
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
    this.isRealtimeActive = true,
    this.socketStatus = RealtimeSocketStatus.connecting,
  });

  final List<LogEntity> logs;
  final PaginationMeta meta;
  final bool isRefreshing;
  final bool isRealtimeActive;
  final RealtimeSocketStatus socketStatus;

  UserAuditLogLoaded copyWith({
    List<LogEntity>? logs,
    PaginationMeta? meta,
    bool? isRefreshing,
    bool? isRealtimeActive,
    RealtimeSocketStatus? socketStatus,
  }) {
    return UserAuditLogLoaded(
      logs: logs ?? this.logs,
      meta: meta ?? this.meta,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isRealtimeActive: isRealtimeActive ?? this.isRealtimeActive,
      socketStatus: socketStatus ?? this.socketStatus,
    );
  }

  @override
  List<Object?> get props => [logs, meta, isRefreshing, isRealtimeActive, socketStatus];
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
    UserAuditLogSocketService? socketService,
  })  : _userId = userId,
        _getLogs = getLogs,
        _socketService = socketService ?? UserAuditLogSocketService(),
        super(const UserAuditLogInitial()) {
    on<LoadUserAuditLogEvent>(_onLoad);
    on<RefreshUserAuditLogEvent>(_onRefresh);
    on<StartRealtimeAuditLogListening>(_onStartRealtimeListening);
    on<StopRealtimeAuditLogListening>(_onStopRealtimeListening);
    on<PollRealtimeAuditLogEvent>(_onPollRealtime);
    on<RealtimeLogReceivedEvent>(_onRealtimeLogReceived);
    on<SocketStatusChangedEvent>(_onSocketStatusChanged);
    on<ReconnectSocketEvent>(_onReconnectSocket);

    _initSocketSubscriptions();
  }

  final String _userId;
  final GetLogsUseCase _getLogs;
  final UserAuditLogSocketService _socketService;

  int _currentPage = 1;
  static const int _limit = 15;
  Timer? _realtimeTimer;
  StreamSubscription<LogEntity>? _logSubscription;
  StreamSubscription<RealtimeSocketStatus>? _statusSubscription;

  void _initSocketSubscriptions() {
    _statusSubscription = _socketService.statusStream.listen((status) {
      if (!isClosed) {
        add(SocketStatusChangedEvent(status));
      }
    });

    _logSubscription = _socketService.onModerationLog.listen((log) {
      if (!isClosed) {
        add(RealtimeLogReceivedEvent(log));
      }
    });
  }

  @override
  Future<void> close() {
    _realtimeTimer?.cancel();
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _socketService.dispose();
    return super.close();
  }

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
          socketStatus: _socketService.currentStatus,
        ),
      );
      // Auto-start socket connection & fallback poll listener
      add(const StartRealtimeAuditLogListening());
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

  Future<void> _onStartRealtimeListening(
    StartRealtimeAuditLogListening event,
    Emitter<UserAuditLogState> emit,
  ) async {
    _socketService.connect(targetUserId: _userId);

    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds.clamp(3, 60)),
      (_) {
        if (!isClosed && _userId.isNotEmpty) {
          add(const PollRealtimeAuditLogEvent());
        }
      },
    );
  }

  Future<void> _onStopRealtimeListening(
    StopRealtimeAuditLogListening event,
    Emitter<UserAuditLogState> emit,
  ) async {
    _realtimeTimer?.cancel();
    _socketService.disconnect();
    if (state is UserAuditLogLoaded) {
      emit((state as UserAuditLogLoaded).copyWith(isRealtimeActive: false));
    }
  }

  Future<void> _onReconnectSocket(
    ReconnectSocketEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    _socketService.reconnect();
    add(RefreshUserAuditLogEvent());
  }

  Future<void> _onSocketStatusChanged(
    SocketStatusChangedEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    if (state is UserAuditLogLoaded) {
      emit((state as UserAuditLogLoaded).copyWith(socketStatus: event.status));
    }
  }

  Future<void> _onRealtimeLogReceived(
    RealtimeLogReceivedEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    final current = state;
    if (current is UserAuditLogLoaded) {
      final existingLogs = List<LogEntity>.from(current.logs);

      // Deduplicate: ignore if log ID already exists
      if (existingLogs.any((l) => l.id == event.log.id)) {
        return;
      }

      // Append-only: Add new log and keep in reverse chronological order (newest first)
      existingLogs.insert(0, event.log);
      existingLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final updatedMeta = PaginationMeta(
        total: current.meta.total + 1,
        page: current.meta.page,
        limit: current.meta.limit,
        totalPages: current.meta.totalPages,
      );

      emit(current.copyWith(
        logs: existingLogs,
        meta: updatedMeta,
        isRealtimeActive: true,
      ));
    }
  }

  Future<void> _onPollRealtime(
    PollRealtimeAuditLogEvent event,
    Emitter<UserAuditLogState> emit,
  ) async {
    if (_userId.isEmpty || _currentPage != 1) return;
    try {
      final query = LogsQuery(
        userId: _userId,
        page: 1,
        limit: _limit,
      );
      final result = await _getLogs(query);
      final current = state;

      if (current is UserAuditLogLoaded) {
        final currentLogs = List<LogEntity>.from(current.logs);
        final newLogs = result.data;
        bool hasAddedNew = false;

        for (final newLog in newLogs) {
          if (!currentLogs.any((l) => l.id == newLog.id)) {
            currentLogs.add(newLog);
            hasAddedNew = true;
          }
        }

        if (hasAddedNew) {
          currentLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(
            current.copyWith(
              logs: currentLogs,
              meta: result.meta,
              isRealtimeActive: true,
            ),
          );
        }
      }
    } catch (_) {
      // Silent error handling for background polling
    }
  }
}
