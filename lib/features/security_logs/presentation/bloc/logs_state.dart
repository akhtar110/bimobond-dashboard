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
    this.isExporting = false,
    this.errorMessage,
    this.successMessage,
    this.exportMessage,
    this.exportIsError = false,
  });

  final List<LogEntity> logs;
  final PaginationMeta meta;
  final LogsQuery query;
  final bool isRefreshing;
  final bool isPaginating;
  final bool isExporting;
  final String? errorMessage;
  final String? successMessage;
  final String? exportMessage;
  final bool exportIsError;

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
    bool? isExporting,
    String? errorMessage,
    String? successMessage,
    String? exportMessage,
    bool? exportIsError,
    bool clearMessages = false,
    bool clearExportMessage = false,
  }) {
    return LogsLoaded(
      logs: logs ?? this.logs,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      isExporting: isExporting ?? this.isExporting,
      errorMessage:
          clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      exportMessage:
          clearExportMessage ? null : (exportMessage ?? this.exportMessage),
      exportIsError: exportIsError ?? this.exportIsError,
    );
  }

  @override
  List<Object?> get props => [
        logs,
        meta,
        query,
        isRefreshing,
        isPaginating,
        isExporting,
        errorMessage,
        successMessage,
        exportMessage,
        exportIsError,
      ];
}

class LogsError extends LogsState {
  const LogsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
