import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../data/datasources/user_audit_log_socket_service.dart';
import '../../data/datasources/user_violations_remote_datasource.dart';
import '../../domain/entities/log_entity.dart';

// EVENTS
abstract class UserViolationsEvent extends Equatable {
  const UserViolationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserViolationsEvent extends UserViolationsEvent {
  const LoadUserViolationsEvent({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

class RefreshUserViolationsEvent extends UserViolationsEvent {
  const RefreshUserViolationsEvent();
}

class StartRealtimeViolationsListening extends UserViolationsEvent {
  const StartRealtimeViolationsListening({this.intervalSeconds = 5});

  final int intervalSeconds;

  @override
  List<Object?> get props => [intervalSeconds];
}

class StopRealtimeViolationsListening extends UserViolationsEvent {
  const StopRealtimeViolationsListening();
}

class PollRealtimeViolationsEvent extends UserViolationsEvent {
  const PollRealtimeViolationsEvent();
}

class RealtimeViolationReceivedEvent extends UserViolationsEvent {
  const RealtimeViolationReceivedEvent(this.log);

  final LogEntity log;

  @override
  List<Object?> get props => [log];
}

class SocketViolationStatusChangedEvent extends UserViolationsEvent {
  const SocketViolationStatusChangedEvent(this.status);

  final RealtimeSocketStatus status;

  @override
  List<Object?> get props => [status];
}

class ReconnectViolationSocketEvent extends UserViolationsEvent {
  const ReconnectViolationSocketEvent();
}

// STATES
abstract class UserViolationsState extends Equatable {
  const UserViolationsState();

  @override
  List<Object?> get props => [];
}

class UserViolationsInitial extends UserViolationsState {
  const UserViolationsInitial();
}

class UserViolationsLoading extends UserViolationsState {
  const UserViolationsLoading();
}

class UserViolationsLoaded extends UserViolationsState {
  const UserViolationsLoaded({
    required this.violations,
    required this.meta,
    this.isRefreshing = false,
    this.isRealtimeActive = true,
    this.socketStatus = RealtimeSocketStatus.connecting,
  });

  final List<LogEntity> violations;
  final PaginationMeta meta;
  final bool isRefreshing;
  final bool isRealtimeActive;
  final RealtimeSocketStatus socketStatus;

  UserViolationsLoaded copyWith({
    List<LogEntity>? violations,
    PaginationMeta? meta,
    bool? isRefreshing,
    bool? isRealtimeActive,
    RealtimeSocketStatus? socketStatus,
  }) {
    return UserViolationsLoaded(
      violations: violations ?? this.violations,
      meta: meta ?? this.meta,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isRealtimeActive: isRealtimeActive ?? this.isRealtimeActive,
      socketStatus: socketStatus ?? this.socketStatus,
    );
  }

  @override
  List<Object?> get props => [violations, meta, isRefreshing, isRealtimeActive, socketStatus];
}

class UserViolationsError extends UserViolationsState {
  const UserViolationsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// BLOC
class UserViolationsBloc extends Bloc<UserViolationsEvent, UserViolationsState> {
  UserViolationsBloc({
    required String userId,
    required UserViolationsRemoteDataSource remoteDataSource,
    UserAuditLogSocketService? socketService,
  })  : _userId = userId,
        _remoteDataSource = remoteDataSource,
        _socketService = socketService ?? UserAuditLogSocketService(),
        super(const UserViolationsInitial()) {
    on<LoadUserViolationsEvent>(_onLoad);
    on<RefreshUserViolationsEvent>(_onRefresh);
    on<StartRealtimeViolationsListening>(_onStartRealtimeListening);
    on<StopRealtimeViolationsListening>(_onStopRealtimeListening);
    on<PollRealtimeViolationsEvent>(_onPollRealtime);
    on<RealtimeViolationReceivedEvent>(_onRealtimeViolationReceived);
    on<SocketViolationStatusChangedEvent>(_onSocketStatusChanged);
    on<ReconnectViolationSocketEvent>(_onReconnectSocket);

    _initSocketSubscriptions();
  }

  final String _userId;
  final UserViolationsRemoteDataSource _remoteDataSource;
  final UserAuditLogSocketService _socketService;

  int _currentPage = 1;
  static const int _limit = 15;
  Timer? _realtimeTimer;
  StreamSubscription<LogEntity>? _logSubscription;
  StreamSubscription<RealtimeSocketStatus>? _statusSubscription;

  void _initSocketSubscriptions() {
    _statusSubscription = _socketService.statusStream.listen((status) {
      if (!isClosed) {
        add(SocketViolationStatusChangedEvent(status));
      }
    });

    _logSubscription = _socketService.onModerationLog.listen((log) {
      if (!isClosed && (log.category == 'MODERATION' || log.targetType == 'VIOLATION')) {
        add(RealtimeViolationReceivedEvent(log));
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
    LoadUserViolationsEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    if (event.page != null) {
      _currentPage = event.page!;
    }

    final current = state;
    final UserViolationsLoaded? previous =
        current is UserViolationsLoaded ? current : null;

    if (previous == null) {
      emit(const UserViolationsLoading());
    } else {
      emit(previous.copyWith(isRefreshing: true));
    }

    try {
      final result = await _remoteDataSource.getUserViolations(
        userId: _userId,
        page: _currentPage,
        limit: _limit,
      );
      emit(
        UserViolationsLoaded(
          violations: result.data,
          meta: result.meta,
          socketStatus: _socketService.currentStatus,
        ),
      );
      add(const StartRealtimeViolationsListening());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (previous != null) {
        emit(previous.copyWith(isRefreshing: false));
      } else {
        emit(UserViolationsError(message));
      }
    }
  }

  Future<void> _onRefresh(
    RefreshUserViolationsEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    add(LoadUserViolationsEvent(page: _currentPage));
  }

  Future<void> _onStartRealtimeListening(
    StartRealtimeViolationsListening event,
    Emitter<UserViolationsState> emit,
  ) async {
    _socketService.connect(targetUserId: _userId);

    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds.clamp(3, 60)),
      (_) {
        if (!isClosed && _userId.isNotEmpty) {
          add(const PollRealtimeViolationsEvent());
        }
      },
    );
  }

  Future<void> _onStopRealtimeListening(
    StopRealtimeViolationsListening event,
    Emitter<UserViolationsState> emit,
  ) async {
    _realtimeTimer?.cancel();
    _socketService.disconnect();
    if (state is UserViolationsLoaded) {
      emit((state as UserViolationsLoaded).copyWith(isRealtimeActive: false));
    }
  }

  Future<void> _onReconnectSocket(
    ReconnectViolationSocketEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    _socketService.reconnect();
    add(const RefreshUserViolationsEvent());
  }

  Future<void> _onSocketStatusChanged(
    SocketViolationStatusChangedEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    if (state is UserViolationsLoaded) {
      emit((state as UserViolationsLoaded).copyWith(socketStatus: event.status));
    }
  }

  Future<void> _onRealtimeViolationReceived(
    RealtimeViolationReceivedEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    final current = state;
    if (current is UserViolationsLoaded) {
      final existingViolations = List<LogEntity>.from(current.violations);

      if (existingViolations.any((l) => l.id == event.log.id)) {
        return;
      }

      existingViolations.insert(0, event.log);
      existingViolations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final updatedMeta = PaginationMeta(
        total: current.meta.total + 1,
        page: current.meta.page,
        limit: current.meta.limit,
        totalPages: current.meta.totalPages,
      );

      emit(current.copyWith(
        violations: existingViolations,
        meta: updatedMeta,
        isRealtimeActive: true,
      ));
    }
  }

  Future<void> _onPollRealtime(
    PollRealtimeViolationsEvent event,
    Emitter<UserViolationsState> emit,
  ) async {
    if (_userId.isEmpty || _currentPage != 1) return;
    try {
      final result = await _remoteDataSource.getUserViolations(
        userId: _userId,
        page: 1,
        limit: _limit,
      );
      final current = state;

      if (current is UserViolationsLoaded) {
        final currentItems = List<LogEntity>.from(current.violations);
        final newItems = result.data;
        bool hasAddedNew = false;

        for (final newItem in newItems) {
          if (!currentItems.any((l) => l.id == newItem.id)) {
            currentItems.add(newItem);
            hasAddedNew = true;
          }
        }

        if (hasAddedNew) {
          currentItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(
            current.copyWith(
              violations: currentItems,
              meta: result.meta,
              isRealtimeActive: true,
            ),
          );
        }
      }
    } catch (_) {
      // Silent background polling
    }
  }
}
