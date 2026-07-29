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
