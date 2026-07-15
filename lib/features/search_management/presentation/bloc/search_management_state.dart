import 'package:equatable/equatable.dart';

import '../../domain/entities/search_management_entities.dart';

abstract class SearchManagementState extends Equatable {
  const SearchManagementState();

  @override
  List<Object?> get props => [];
}

class SearchManagementInitial extends SearchManagementState {
  const SearchManagementInitial();
}

class SearchManagementLoading extends SearchManagementState {
  const SearchManagementLoading();
}

class SearchManagementEmpty extends SearchManagementState {
  const SearchManagementEmpty({
    required this.filter,
    required this.uiTab,
    this.overview,
    this.message,
  });

  final SearchManagementFilterQuery filter;
  final SearchManagementTab uiTab;
  final SearchManagementOverviewEntity? overview;
  final String? message;

  @override
  List<Object?> get props => [filter, uiTab, overview, message];
}

class SearchManagementLoaded extends SearchManagementState {
  const SearchManagementLoaded({
    required this.filter,
    required this.uiTab,
    required this.overview,
    required this.searchResult,
    required this.trends,
    required this.history,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.message,
    this.isErrorMessage = false,
    this.detailsPayload,
  });

  final SearchManagementFilterQuery filter;
  final SearchManagementTab uiTab;
  final SearchManagementOverviewEntity overview;
  final UnifiedSearchResult searchResult;
  final List<SearchTrendEntity> trends;
  final SearchHistoryPageResult history;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? message;
  final bool isErrorMessage;
  final Object? detailsPayload;

  bool get hasMore {
    switch (uiTab) {
      case SearchManagementTab.searches:
        return !history.meta.hasReachedMax;
      case SearchManagementTab.users:
        return searchResult.users?.meta.hasMore ?? false;
      case SearchManagementTab.sounds:
        return searchResult.sounds?.meta.hasMore ?? false;
      case SearchManagementTab.hashtags:
        return searchResult.hashtags?.meta.hasMore ?? false;
      case SearchManagementTab.overview:
      case SearchManagementTab.trends:
        return false;
    }
  }

  SearchManagementLoaded copyWith({
    SearchManagementFilterQuery? filter,
    SearchManagementTab? uiTab,
    SearchManagementOverviewEntity? overview,
    UnifiedSearchResult? searchResult,
    List<SearchTrendEntity>? trends,
    SearchHistoryPageResult? history,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? message,
    bool? isErrorMessage,
    Object? detailsPayload,
    bool clearMessage = false,
    bool clearDetails = false,
  }) {
    return SearchManagementLoaded(
      filter: filter ?? this.filter,
      uiTab: uiTab ?? this.uiTab,
      overview: overview ?? this.overview,
      searchResult: searchResult ?? this.searchResult,
      trends: trends ?? this.trends,
      history: history ?? this.history,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: clearMessage ? null : (message ?? this.message),
      isErrorMessage: isErrorMessage ?? this.isErrorMessage,
      detailsPayload:
          clearDetails ? null : (detailsPayload ?? this.detailsPayload),
    );
  }

  @override
  List<Object?> get props => [
        filter,
        uiTab,
        overview,
        searchResult,
        trends,
        history,
        isLoadingMore,
        isRefreshing,
        message,
        isErrorMessage,
        detailsPayload,
      ];
}

class SearchManagementError extends SearchManagementState {
  const SearchManagementError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
