import 'package:equatable/equatable.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/log_entity.dart';

abstract class LogsState extends Equatable {
  const LogsState();

  @override
  List<Object?> get props => [];
}

class LogsInitial extends LogsState {
  const LogsInitial();
}

class LogsLoading extends LogsState {
  const LogsLoading();
}

class LogsLoaded extends LogsState {
  const LogsLoaded({
    required this.logs,
    required this.meta,
    required this.query,
    this.isRefreshing = false,
    this.isPaginating = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<LogEntity> logs;
  final PaginationMeta meta;
  final LogsQuery query;
  final bool isRefreshing;
  final bool isPaginating;
  final String? errorMessage;
  final String? successMessage;

  UserEntity? get selectedUser => query.user;
  String? get selectedActorRole => query.actorRole;
  String? get selectedCategory => query.category;
  String? get selectedAction => query.action;
  int get currentPage => meta.page;
  int get limit => meta.limit;
  int get totalPages => meta.totalPages;
  int get totalItems => meta.total;

  LogsLoaded copyWith({
    List<LogEntity>? logs,
    PaginationMeta? meta,
    LogsQuery? query,
    bool? isRefreshing,
    bool? isPaginating,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return LogsLoaded(
      logs: logs ?? this.logs,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      errorMessage:
          clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        logs,
        meta,
        query,
        isRefreshing,
        isPaginating,
        errorMessage,
        successMessage,
      ];
}

class LogsError extends LogsState {
  const LogsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
