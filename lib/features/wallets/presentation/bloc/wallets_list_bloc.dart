import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class WalletsListEvent {}

class LoadWalletsListEvent extends WalletsListEvent {}

class WalletsListPageChangedEvent extends WalletsListEvent {
  WalletsListPageChangedEvent(this.page);
  final int page;
}

class WalletsListSearchEvent extends WalletsListEvent {
  WalletsListSearchEvent(this.search);
  final String search;
}

class WalletsListApplySearchEvent extends WalletsListEvent {
  WalletsListApplySearchEvent(this.search);
  final String search;
}

class WalletsListSortChangedEvent extends WalletsListEvent {
  WalletsListSortChangedEvent(this.sort);
  final WalletSort sort;
}

class WalletsListBalanceFilterEvent extends WalletsListEvent {
  WalletsListBalanceFilterEvent({this.minBalance, this.maxBalance});
  final double? minBalance;
  final double? maxBalance;
}

class ClearWalletsListFiltersEvent extends WalletsListEvent {}

abstract class WalletsListState {}

class WalletsListInitial extends WalletsListState {}

class WalletsListLoading extends WalletsListState {}

class WalletsListLoaded extends WalletsListState {
  WalletsListLoaded({
    required this.wallets,
    required this.meta,
    required this.query,
    this.isRefreshing = false,
  });

  final List<WalletListItemEntity> wallets;
  final PaginationMeta meta;
  final WalletsListQuery query;
  final bool isRefreshing;

  WalletsListLoaded copyWith({
    List<WalletListItemEntity>? wallets,
    PaginationMeta? meta,
    WalletsListQuery? query,
    bool? isRefreshing,
  }) {
    return WalletsListLoaded(
      wallets: wallets ?? this.wallets,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class WalletsListError extends WalletsListState {
  WalletsListError(this.message);
  final String message;
}

class WalletsListBloc extends Bloc<WalletsListEvent, WalletsListState> {
  WalletsListBloc({required GetWalletsUseCase getWallets})
      : _getWallets = getWallets,
        super(WalletsListInitial()) {
    on<LoadWalletsListEvent>(_onLoad);
    on<WalletsListPageChangedEvent>(_onPageChanged);
    on<WalletsListSearchEvent>(_onSearch);
    on<WalletsListApplySearchEvent>(_onApplySearch);
    on<WalletsListSortChangedEvent>(_onSortChanged);
    on<WalletsListBalanceFilterEvent>(_onBalanceFilter);
    on<ClearWalletsListFiltersEvent>(_onClearFilters);
  }

  final GetWalletsUseCase _getWallets;
  WalletsListQuery _query = const WalletsListQuery();
  Timer? _searchDebounce;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _fetch(Emitter<WalletsListState> emit, {bool refresh = false}) async {
    final current = state;
    if (current is WalletsListLoaded && refresh) {
      emit(current.copyWith(isRefreshing: true));
    } else if (current is! WalletsListLoaded) {
      emit(WalletsListLoading());
    }

    try {
      final result = await _getWallets(_query);
      emit(WalletsListLoaded(
        wallets: result.data,
        meta: result.meta,
        query: _query,
      ));
    } catch (e) {
      emit(WalletsListError(e.toString()));
    }
  }

  Future<void> _onLoad(
    LoadWalletsListEvent event,
    Emitter<WalletsListState> emit,
  ) =>
      _fetch(emit, refresh: state is WalletsListLoaded);

  Future<void> _onPageChanged(
    WalletsListPageChangedEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    _query = _query.copyWith(page: event.page);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onSearch(
    WalletsListSearchEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      add(WalletsListApplySearchEvent(event.search));
    });
  }

  Future<void> _onApplySearch(
    WalletsListApplySearchEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    final trimmed = event.search.trim();
    _query = _query.copyWith(
      page: 1,
      search: trimmed.isEmpty ? null : trimmed,
      clearSearch: trimmed.isEmpty,
    );
    await _fetch(emit, refresh: true);
  }

  Future<void> _onSortChanged(
    WalletsListSortChangedEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    _query = _query.copyWith(page: 1, sort: event.sort);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onBalanceFilter(
    WalletsListBalanceFilterEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    _query = _query.copyWith(
      page: 1,
      minBalance: event.minBalance,
      maxBalance: event.maxBalance,
      clearMinBalance: event.minBalance == null,
      clearMaxBalance: event.maxBalance == null,
    );
    await _fetch(emit, refresh: true);
  }

  Future<void> _onClearFilters(
    ClearWalletsListFiltersEvent event,
    Emitter<WalletsListState> emit,
  ) async {
    _query = const WalletsListQuery();
    await _fetch(emit, refresh: true);
  }
}
