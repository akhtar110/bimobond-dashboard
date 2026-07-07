import 'package:equatable/equatable.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/search_history.dart';

abstract class SearchHistoryState extends Equatable {
  const SearchHistoryState();

  @override
  List<Object?> get props => [];
}

class SearchHistoryInitial extends SearchHistoryState {}

class SearchHistoryLoading extends SearchHistoryState {}

class SearchHistoryLoaded extends SearchHistoryState {
  const SearchHistoryLoaded({
    required this.items,
    required this.meta,
    required this.query,
    this.overview,
    this.selectedIds = const {},
    this.scopedUserId,
    this.isActioning = false,
    this.message,
    this.isErrorMessage = false,
  });

  final List<SearchHistoryEntity> items;
  final PaginationMeta meta;
  final SearchHistoryQuery query;
  final SearchHistoryOverviewEntity? overview;
  final Set<String> selectedIds;
  final String? scopedUserId;
  final bool isActioning;
  final String? message;
  final bool isErrorMessage;

  bool get isUserScoped => scopedUserId != null;

  SearchHistoryLoaded copyWith({
    List<SearchHistoryEntity>? items,
    PaginationMeta? meta,
    SearchHistoryQuery? query,
    SearchHistoryOverviewEntity? overview,
    Set<String>? selectedIds,
    String? scopedUserId,
    bool? isActioning,
    String? message,
    bool clearMessage = false,
    bool? isErrorMessage,
  }) {
    return SearchHistoryLoaded(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      overview: overview ?? this.overview,
      selectedIds: selectedIds ?? this.selectedIds,
      scopedUserId: scopedUserId ?? this.scopedUserId,
      isActioning: isActioning ?? this.isActioning,
      message: clearMessage ? null : (message ?? this.message),
      isErrorMessage: isErrorMessage ?? this.isErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        meta,
        query,
        overview,
        selectedIds,
        scopedUserId,
        isActioning,
        message,
        isErrorMessage,
      ];
}

class SearchHistoryError extends SearchHistoryState {
  const SearchHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
