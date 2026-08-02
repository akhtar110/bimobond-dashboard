import 'package:equatable/equatable.dart';

import '../../domain/entities/user_history_entity.dart';

sealed class UserHistoryState extends Equatable {
  const UserHistoryState({
    this.userId = '',
    this.query = const UserHistoryQuery(),
    this.hasLoadedOnce = false,
  });

  final String userId;
  final UserHistoryQuery query;
  final bool hasLoadedOnce;

  @override
  List<Object?> get props => [userId, query, hasLoadedOnce];
}

class UserHistoryInitial extends UserHistoryState {
  const UserHistoryInitial({
    super.userId,
    super.query,
    super.hasLoadedOnce,
  });
}

class UserHistoryLoading extends UserHistoryState {
  const UserHistoryLoading({
    required super.userId,
    required super.query,
    super.hasLoadedOnce,
  });
}

class UserHistoryLoaded extends UserHistoryState {
  const UserHistoryLoaded({
    required super.userId,
    required super.query,
    required this.items,
    required this.meta,
    super.hasLoadedOnce = true,
  });

  final List<UserHistoryEntity> items;
  final UserHistoryMetaEntity meta;

  @override
  List<Object?> get props => [...super.props, items, meta];
}

class UserHistoryEmpty extends UserHistoryState {
  const UserHistoryEmpty({
    required super.userId,
    required super.query,
    required this.meta,
    super.hasLoadedOnce = true,
  });

  final UserHistoryMetaEntity meta;

  @override
  List<Object?> get props => [...super.props, meta];
}

class UserHistoryLoadingMore extends UserHistoryState {
  const UserHistoryLoadingMore({
    required super.userId,
    required super.query,
    required this.items,
    required this.meta,
    super.hasLoadedOnce = true,
  });

  final List<UserHistoryEntity> items;
  final UserHistoryMetaEntity meta;

  @override
  List<Object?> get props => [...super.props, items, meta];
}

class UserHistoryError extends UserHistoryState {
  const UserHistoryError({
    required super.userId,
    required super.query,
    required this.message,
    this.items = const [],
    this.meta,
    super.hasLoadedOnce,
  });

  final String message;
  final List<UserHistoryEntity> items;
  final UserHistoryMetaEntity? meta;

  @override
  List<Object?> get props => [...super.props, message, items, meta];
}
