import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../utils/logs_export_service.dart';

abstract class LogsEvent extends Equatable {
  const LogsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLogsEvent extends LogsEvent {
  const LoadLogsEvent({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

class RefreshLogsEvent extends LogsEvent {
  const RefreshLogsEvent();
}

class LogsPageChangedEvent extends LogsEvent {
  const LogsPageChangedEvent(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class LogsLimitChangedEvent extends LogsEvent {
  const LogsLimitChangedEvent(this.limit);

  final int limit;

  @override
  List<Object?> get props => [limit];
}

class LogsUserChangedEvent extends LogsEvent {
  const LogsUserChangedEvent(this.user);

  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}

class LogsActorRoleChangedEvent extends LogsEvent {
  const LogsActorRoleChangedEvent(this.actorRole);

  final String? actorRole;

  @override
  List<Object?> get props => [actorRole];
}

class LogsCategoryChangedEvent extends LogsEvent {
  const LogsCategoryChangedEvent(this.category);

  final String? category;

  @override
  List<Object?> get props => [category];
}

class LogsActionChangedEvent extends LogsEvent {
  const LogsActionChangedEvent(this.action);

  final String? action;

  @override
  List<Object?> get props => [action];
}

class LogsApplyFiltersEvent extends LogsEvent {
  const LogsApplyFiltersEvent({
    this.user,
    this.userId,
    this.actorRole,
    this.category,
    this.action,
    this.from,
    this.to,
    this.deviceId,
    this.limit,
  });

  final UserEntity? user;
  final String? userId;
  final String? actorRole;
  final String? category;
  final String? action;
  final DateTime? from;
  final DateTime? to;
  final String? deviceId;
  final int? limit;

  @override
  List<Object?> get props => [
        user,
        userId,
        actorRole,
        category,
        action,
        from,
        to,
        deviceId,
        limit,
      ];
}

class LogsResetFiltersEvent extends LogsEvent {
  const LogsResetFiltersEvent();
}

class ClearLogsMessageEvent extends LogsEvent {
  const ClearLogsMessageEvent();
}

class ExportLogsEvent extends LogsEvent {
  const ExportLogsEvent({required this.format});

  final LogsExportFormat format;

  @override
  List<Object?> get props => [format];
}

class ClearLogsExportMessageEvent extends LogsEvent {
  const ClearLogsExportMessageEvent();
}

