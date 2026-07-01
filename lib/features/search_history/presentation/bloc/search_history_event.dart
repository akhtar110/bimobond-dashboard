import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/search_history.dart';

abstract class SearchHistoryEvent extends Equatable {
  const SearchHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadSearchHistory extends SearchHistoryEvent {
  const LoadSearchHistory({this.page = 1, this.refreshOverview = false});

  final int page;
  final bool refreshOverview;
}

class LoadUserSearchHistory extends SearchHistoryEvent {
  const LoadUserSearchHistory({required this.userId, this.page = 1});

  final String userId;
  final int page;
}

class DeleteSearchHistoryItem extends SearchHistoryEvent {
  const DeleteSearchHistoryItem(this.id);

  final String id;
}

class ClearSearchHistory extends SearchHistoryEvent {
  const ClearSearchHistory({this.userId, this.category});

  final String? userId;
  final String? category;
}

class BulkDeleteSearchHistory extends SearchHistoryEvent {
  const BulkDeleteSearchHistory(this.ids);

  final List<String> ids;
}

class BulkClearUsersSearchHistory extends SearchHistoryEvent {
  const BulkClearUsersSearchHistory({
    required this.userIds,
    this.category,
  });

  final List<String> userIds;
  final String? category;
}

class UpdateFilters extends SearchHistoryEvent {
  const UpdateFilters({
    this.search,
    this.category,
    this.dateRange,
    this.sort,
    this.clearSearch = false,
    this.clearCategory = false,
    this.clearDateRange = false,
  });

  final String? search;
  final String? category;
  final DateTimeRange? dateRange;
  final SearchHistorySort? sort;
  final bool clearSearch;
  final bool clearCategory;
  final bool clearDateRange;
}

class ClearFilters extends SearchHistoryEvent {
  const ClearFilters();
}

class ToggleSearchHistorySelection extends SearchHistoryEvent {
  const ToggleSearchHistorySelection(this.id);

  final String id;
}

class SelectAllSearchHistory extends SearchHistoryEvent {
  const SelectAllSearchHistory();
}

class ClearSearchHistorySelection extends SearchHistoryEvent {
  const ClearSearchHistorySelection();
}

class SetSearchHistoryScope extends SearchHistoryEvent {
  const SetSearchHistoryScope({this.userId});

  final String? userId;
}
