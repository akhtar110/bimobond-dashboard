import 'package:equatable/equatable.dart';

import '../../domain/entities/user_interest_entities.dart';

abstract class UserInterestsEvent extends Equatable {
  const UserInterestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserInterestsEvent extends UserInterestsEvent {
  const LoadUserInterestsEvent(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class RefreshUserInterestsEvent extends UserInterestsEvent {
  const RefreshUserInterestsEvent(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class SearchInterestsEvent extends UserInterestsEvent {
  const SearchInterestsEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterByPreferenceEvent extends UserInterestsEvent {
  const FilterByPreferenceEvent(this.preference);

  final UserInterestPreference? preference;

  @override
  List<Object?> get props => [preference];
}

class FilterBySourceEvent extends UserInterestsEvent {
  const FilterBySourceEvent(this.source);

  final UserInterestSource? source;

  @override
  List<Object?> get props => [source];
}

class FilterByDateRangeEvent extends UserInterestsEvent {
  const FilterByDateRangeEvent({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [from, to];
}

class ClearUserInterestsFiltersEvent extends UserInterestsEvent {
  const ClearUserInterestsFiltersEvent();
}
