import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class UserHistoryEvent extends Equatable {
  const UserHistoryEvent();

  @override
  List<Object?> get props => const [];
}

class SetUserHistoryUserId extends UserHistoryEvent {
  const SetUserHistoryUserId(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LoadUserHistory extends UserHistoryEvent {
  const LoadUserHistory({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

class RefreshUserHistory extends UserHistoryEvent {
  const RefreshUserHistory();
}

class LoadNextUserHistoryPage extends UserHistoryEvent {
  const LoadNextUserHistoryPage();
}

class ChangeUserHistoryPage extends UserHistoryEvent {
  const ChangeUserHistoryPage(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class ChangeUserHistoryFilters extends UserHistoryEvent {
  const ChangeUserHistoryFilters({
    this.dateRange,
    this.types,
    this.clearDateRange = false,
    this.clearTypes = false,
  });

  final DateTimeRange? dateRange;
  final List<String>? types;
  final bool clearDateRange;
  final bool clearTypes;

  @override
  List<Object?> get props => [dateRange, types, clearDateRange, clearTypes];
}

class ClearUserHistoryFilters extends UserHistoryEvent {
  const ClearUserHistoryFilters();
}

class StartRealtimeUserHistoryListening extends UserHistoryEvent {
  const StartRealtimeUserHistoryListening({this.intervalSeconds = 5});

  final int intervalSeconds;

  @override
  List<Object?> get props => [intervalSeconds];
}

class StopRealtimeUserHistoryListening extends UserHistoryEvent {
  const StopRealtimeUserHistoryListening();
}

class PollRealtimeUserHistory extends UserHistoryEvent {
  const PollRealtimeUserHistory();
}
