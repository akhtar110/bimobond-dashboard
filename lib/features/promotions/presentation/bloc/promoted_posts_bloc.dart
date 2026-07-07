import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/usecases/promotion_usecases.dart';

enum PromotedPostsSortField {
  views,
  likes,
  engagement,
  impressions,
  spent,
  campaigns,
}

abstract class PromotedPostsEvent extends Equatable {
  const PromotedPostsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPromotedPostsEvent extends PromotedPostsEvent {
  const LoadPromotedPostsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
  @override
  List<Object?> get props => [refresh, page];
}

class LoadMorePromotedPostsEvent extends PromotedPostsEvent {
  const LoadMorePromotedPostsEvent();
}

class SearchPromotedPostsEvent extends PromotedPostsEvent {
  const SearchPromotedPostsEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class FilterPromotedPostsStatusEvent extends PromotedPostsEvent {
  const FilterPromotedPostsStatusEvent(this.status);
  final String? status;
  @override
  List<Object?> get props => [status];
}

class SortPromotedPostsEvent extends PromotedPostsEvent {
  const SortPromotedPostsEvent(this.field);
  final PromotedPostsSortField field;
  @override
  List<Object?> get props => [field];
}

class ClearPromotedPostsFiltersEvent extends PromotedPostsEvent {
  const ClearPromotedPostsFiltersEvent();
}

abstract class PromotedPostsState extends Equatable {
  const PromotedPostsState();
  @override
  List<Object?> get props => [];
}

class PromotedPostsInitial extends PromotedPostsState {}

class PromotedPostsLoading extends PromotedPostsState {
  const PromotedPostsLoading({
    this.query = const PromotedPostsQuery(),
    this.sortField = PromotedPostsSortField.views,
  });

  final PromotedPostsQuery query;
  final PromotedPostsSortField sortField;

  @override
  List<Object?> get props => [query, sortField];
}

class PromotedPostsEmpty extends PromotedPostsState {
  const PromotedPostsEmpty({
    required this.query,
    required this.sortField,
    this.isLoading = false,
  });
  final PromotedPostsQuery query;
  final PromotedPostsSortField sortField;
  final bool isLoading;
  @override
  List<Object?> get props => [query, sortField, isLoading];
}

class PromotedPostsLoaded extends PromotedPostsState {
  const PromotedPostsLoaded({
    required this.posts,
    required this.meta,
    required this.query,
    required this.sortField,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.message,
    this.isError = false,
  });

  final List<PromotedPostEntity> posts;
  final PaginationMeta meta;
  final PromotedPostsQuery query;
  final PromotedPostsSortField sortField;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? message;
  final bool isError;

  PromotedPostsLoaded copyWith({
    List<PromotedPostEntity>? posts,
    PaginationMeta? meta,
    PromotedPostsQuery? query,
    PromotedPostsSortField? sortField,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return PromotedPostsLoaded(
      posts: posts ?? this.posts,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      sortField: sortField ?? this.sortField,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props =>
      [posts, meta, query, sortField, isRefreshing, isLoadingMore, message, isError];
}

class PromotedPostsError extends PromotedPostsState {
  const PromotedPostsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class PromotedPostsBloc extends Bloc<PromotedPostsEvent, PromotedPostsState> {
  PromotedPostsBloc({required GetPromotedPostsUseCase getPromotedPosts})
      : _getPromotedPosts = getPromotedPosts,
        super(PromotedPostsInitial()) {
    on<LoadPromotedPostsEvent>(_onLoad);
    on<LoadMorePromotedPostsEvent>(_onLoadMore);
    on<SearchPromotedPostsEvent>(_onSearch);
    on<FilterPromotedPostsStatusEvent>(_onFilterStatus);
    on<SortPromotedPostsEvent>(_onSort);
    on<ClearPromotedPostsFiltersEvent>(_onClearFilters);
  }

  final GetPromotedPostsUseCase _getPromotedPosts;
  Timer? _searchDebounce;
  PromotedPostsQuery _query = const PromotedPostsQuery();
  PromotedPostsSortField _sortField = PromotedPostsSortField.views;
  bool _loadMoreBusy = false;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  List<PromotedPostEntity> _sorted(List<PromotedPostEntity> posts) {
    final sorted = List<PromotedPostEntity>.from(posts);
    int compareNum(num a, num b) => a.compareTo(b);
    sorted.sort((a, b) {
      switch (_sortField) {
        case PromotedPostsSortField.likes:
          return compareNum(b.statistics.likes, a.statistics.likes);
        case PromotedPostsSortField.engagement:
          return compareNum(
            b.statistics.engagementRate,
            a.statistics.engagementRate,
          );
        case PromotedPostsSortField.impressions:
          return compareNum(
            b.promotion.totalImpressions,
            a.promotion.totalImpressions,
          );
        case PromotedPostsSortField.spent:
          return compareNum(
            b.promotion.totalSpentCoins,
            a.promotion.totalSpentCoins,
          );
        case PromotedPostsSortField.campaigns:
          return compareNum(
            b.promotion.totalCampaigns,
            a.promotion.totalCampaigns,
          );
        case PromotedPostsSortField.views:
          return compareNum(b.statistics.views, a.statistics.views);
      }
    });
    return sorted;
  }

  Future<void> _onLoad(
    LoadPromotedPostsEvent event,
    Emitter<PromotedPostsState> emit,
  ) async {
    final current = state;
    if (event.refresh) {
      _query = _query.copyWith(page: 1);
    } else if (event.page != null) {
      _query = _query.copyWith(page: event.page);
    }

    if (current is PromotedPostsLoaded) {
      emit(current.copyWith(isRefreshing: true, isLoadingMore: false, clearMessage: true));
    } else if (current is PromotedPostsEmpty) {
      emit(
        PromotedPostsEmpty(
          query: _query,
          sortField: _sortField,
          isLoading: true,
        ),
      );
    } else if (current is PromotedPostsInitial ||
        current is PromotedPostsLoading ||
        current is PromotedPostsError) {
      emit(PromotedPostsLoading(query: _query, sortField: _sortField));
    }

    try {
      final result = await _getPromotedPosts(_query);
      final sorted = _sorted(result.data);
      if (sorted.isEmpty) {
        emit(PromotedPostsEmpty(query: _query, sortField: _sortField));
      } else {
        emit(
          PromotedPostsLoaded(
            posts: sorted,
            meta: result.meta,
            query: _query,
            sortField: _sortField,
          ),
        );
      }
    } catch (e) {
      if (current is PromotedPostsLoaded) {
        emit(current.copyWith(
          isRefreshing: false,
          message: e.toString(),
          isError: true,
        ));
      } else if (current is PromotedPostsEmpty) {
        emit(PromotedPostsEmpty(query: _query, sortField: _sortField));
      } else {
        emit(PromotedPostsError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(
    LoadMorePromotedPostsEvent event,
    Emitter<PromotedPostsState> emit,
  ) async {
    final current = state;
    if (current is! PromotedPostsLoaded) return;
    if (current.meta.hasReachedMax ||
        current.isLoadingMore ||
        current.isRefreshing ||
        _loadMoreBusy) {
      return;
    }

    _loadMoreBusy = true;
    final nextPage = current.meta.page + 1;
    _query = _query.copyWith(page: nextPage);
    emit(current.copyWith(isLoadingMore: true, clearMessage: true));

    try {
      final result = await _getPromotedPosts(_query);
      final merged = _sorted([...current.posts, ...result.data]);
      emit(
        PromotedPostsLoaded(
          posts: merged,
          meta: result.meta,
          query: _query,
          sortField: _sortField,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isLoadingMore: false,
          message: e.toString(),
          isError: true,
        ),
      );
    } finally {
      _loadMoreBusy = false;
    }
  }

  void _onSearch(
    SearchPromotedPostsEvent event,
    Emitter<PromotedPostsState> emit,
  ) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _query = _query.copyWith(
        page: 1,
        search: event.query.trim(),
        clearSearch: event.query.trim().isEmpty,
      );
      add(const LoadPromotedPostsEvent(refresh: true));
    });
  }

  void _onFilterStatus(
    FilterPromotedPostsStatusEvent event,
    Emitter<PromotedPostsState> emit,
  ) {
    _query = _query.copyWith(
      page: 1,
      status: event.status,
      clearStatus: event.status == null,
    );
    add(const LoadPromotedPostsEvent(refresh: true));
  }

  void _onSort(SortPromotedPostsEvent event, Emitter<PromotedPostsState> emit) {
    _sortField = event.field;
    final current = state;
    if (current is PromotedPostsLoaded) {
      emit(current.copyWith(posts: _sorted(current.posts), sortField: _sortField));
    } else if (current is PromotedPostsEmpty) {
      emit(PromotedPostsEmpty(query: _query, sortField: _sortField));
    }
  }

  void _onClearFilters(
    ClearPromotedPostsFiltersEvent event,
    Emitter<PromotedPostsState> emit,
  ) {
    _searchDebounce?.cancel();
    _query = const PromotedPostsQuery();
    add(const LoadPromotedPostsEvent(refresh: true));
  }
}
