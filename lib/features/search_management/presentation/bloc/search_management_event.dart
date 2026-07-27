import 'package:equatable/equatable.dart';

import '../../domain/entities/search_management_entities.dart';

abstract class SearchManagementEvent extends Equatable {
  const SearchManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadSearchManagementEvent extends SearchManagementEvent {
  const LoadSearchManagementEvent();
}

class RefreshSearchManagementEvent extends SearchManagementEvent {
  const RefreshSearchManagementEvent();
}

class SearchManagementQueryChangedEvent extends SearchManagementEvent {
  const SearchManagementQueryChangedEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchManagementCategoryChangedEvent extends SearchManagementEvent {
  const SearchManagementCategoryChangedEvent(this.apiTab);
  final SearchApiTab apiTab;

  @override
  List<Object?> get props => [apiTab];
}

class SearchManagementUiTabChangedEvent extends SearchManagementEvent {
  const SearchManagementUiTabChangedEvent(this.tab);
  final SearchManagementTab tab;

  @override
  List<Object?> get props => [tab];
}

class SearchManagementDateChangedEvent extends SearchManagementEvent {
  const SearchManagementDateChangedEvent({this.from, this.to, this.clear = false});
  final DateTime? from;
  final DateTime? to;
  final bool clear;

  @override
  List<Object?> get props => [from, to, clear];
}

class SearchManagementSortChangedEvent extends SearchManagementEvent {
  const SearchManagementSortChangedEvent(this.sort);
  final SearchManagementSort sort;

  @override
  List<Object?> get props => [sort];
}

class SearchManagementTrendingFilterChangedEvent extends SearchManagementEvent {
  const SearchManagementTrendingFilterChangedEvent(this.trendingOnly);
  final bool trendingOnly;

  @override
  List<Object?> get props => [trendingOnly];
}

class SearchManagementFilterAppliedEvent extends SearchManagementEvent {
  const SearchManagementFilterAppliedEvent({this.filter});

  /// When set, replaces advanced filter fields (keeps current search query).
  final SearchManagementFilterQuery? filter;

  @override
  List<Object?> get props => [filter];
}

class SearchManagementFilterResetEvent extends SearchManagementEvent {
  const SearchManagementFilterResetEvent();
}

class SearchManagementLoadNextPageEvent extends SearchManagementEvent {
  const SearchManagementLoadNextPageEvent();
}

class SearchManagementOpenDetailsEvent extends SearchManagementEvent {
  const SearchManagementOpenDetailsEvent(this.payload);
  final Object payload;

  @override
  List<Object?> get props => [payload];
}

class SearchManagementSaveHistoryEvent extends SearchManagementEvent {
  const SearchManagementSaveHistoryEvent();
}

class SearchManagementClearHistoryEvent extends SearchManagementEvent {
  const SearchManagementClearHistoryEvent({this.category});
  final String? category;

  @override
  List<Object?> get props => [category];
}
