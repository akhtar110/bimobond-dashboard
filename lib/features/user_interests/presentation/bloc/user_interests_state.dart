import 'package:equatable/equatable.dart';

import '../../domain/entities/user_interest_entities.dart';

abstract class UserInterestsState extends Equatable {
  const UserInterestsState();

  @override
  List<Object?> get props => [];
}

class UserInterestsInitial extends UserInterestsState {
  const UserInterestsInitial();
}

class UserInterestsLoading extends UserInterestsState {
  const UserInterestsLoading();
}

class UserInterestsEmpty extends UserInterestsState {
  const UserInterestsEmpty({
    required this.userId,
    required this.meta,
    this.filter = const UserInterestsFilterQuery(),
  });

  final String userId;
  final UserInterestsMetaEntity meta;
  final UserInterestsFilterQuery filter;

  @override
  List<Object?> get props => [userId, meta, filter];
}

class UserInterestsLoaded extends UserInterestsState {
  const UserInterestsLoaded({
    required this.userId,
    required this.response,
    required this.filteredInterests,
    required this.filteredNotInterests,
    this.filter = const UserInterestsFilterQuery(),
    this.isRefreshing = false,
  });

  final String userId;
  final UserInterestsResponseEntity response;
  final List<UserInterestEntity> filteredInterests;
  final List<UserInterestEntity> filteredNotInterests;
  final UserInterestsFilterQuery filter;
  final bool isRefreshing;

  UserInterestsMetaEntity get meta => response.meta;

  UserInterestsLoaded copyWith({
    UserInterestsResponseEntity? response,
    List<UserInterestEntity>? filteredInterests,
    List<UserInterestEntity>? filteredNotInterests,
    UserInterestsFilterQuery? filter,
    bool? isRefreshing,
  }) {
    return UserInterestsLoaded(
      userId: userId,
      response: response ?? this.response,
      filteredInterests: filteredInterests ?? this.filteredInterests,
      filteredNotInterests: filteredNotInterests ?? this.filteredNotInterests,
      filter: filter ?? this.filter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        response,
        filteredInterests,
        filteredNotInterests,
        filter,
        isRefreshing,
      ];
}

class UserInterestsError extends UserInterestsState {
  const UserInterestsError({
    required this.message,
    this.userId,
    this.isForbidden = false,
    this.isNotFound = false,
  });

  final String message;
  final String? userId;
  final bool isForbidden;
  final bool isNotFound;

  @override
  List<Object?> get props => [message, userId, isForbidden, isNotFound];
}
