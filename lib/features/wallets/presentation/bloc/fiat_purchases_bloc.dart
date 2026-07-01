import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class FiatPurchasesEvent {}

class LoadFiatPurchasesEvent extends FiatPurchasesEvent {}

class FiatPurchasesPageChangedEvent extends FiatPurchasesEvent {
  FiatPurchasesPageChangedEvent(this.page);
  final int page;
}

class FiatPurchasesFilterChangedEvent extends FiatPurchasesEvent {
  FiatPurchasesFilterChangedEvent(this.query);
  final FiatPurchasesQuery query;
}

class FiatPurchasesSearchEvent extends FiatPurchasesEvent {
  FiatPurchasesSearchEvent(this.search);
  final String search;
}

class FiatPurchasesApplySearchEvent extends FiatPurchasesEvent {
  FiatPurchasesApplySearchEvent(this.search);
  final String search;
}

abstract class FiatPurchasesState {}

class FiatPurchasesInitial extends FiatPurchasesState {}

class FiatPurchasesLoading extends FiatPurchasesState {}

class FiatPurchasesLoaded extends FiatPurchasesState {
  FiatPurchasesLoaded({
    required this.purchases,
    required this.meta,
    required this.query,
    this.isRefreshing = false,
  });

  final List<FiatPurchaseEntity> purchases;
  final PaginationMeta meta;
  final FiatPurchasesQuery query;
  final bool isRefreshing;

  FiatPurchasesLoaded copyWith({
    List<FiatPurchaseEntity>? purchases,
    PaginationMeta? meta,
    FiatPurchasesQuery? query,
    bool? isRefreshing,
  }) {
    return FiatPurchasesLoaded(
      purchases: purchases ?? this.purchases,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class FiatPurchasesError extends FiatPurchasesState {
  FiatPurchasesError(this.message);
  final String message;
}

class FiatPurchasesBloc extends Bloc<FiatPurchasesEvent, FiatPurchasesState> {
  FiatPurchasesBloc({required GetFiatPurchasesUseCase getPurchases})
      : _getPurchases = getPurchases,
        super(FiatPurchasesInitial()) {
    on<LoadFiatPurchasesEvent>(_onLoad);
    on<FiatPurchasesPageChangedEvent>(_onPageChanged);
    on<FiatPurchasesFilterChangedEvent>(_onFilterChanged);
    on<FiatPurchasesSearchEvent>(_onSearch);
    on<FiatPurchasesApplySearchEvent>(_onApplySearch);
  }

  final GetFiatPurchasesUseCase _getPurchases;
  FiatPurchasesQuery _query = const FiatPurchasesQuery();
  Timer? _searchDebounce;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _fetch(
    Emitter<FiatPurchasesState> emit, {
    bool refresh = false,
  }) async {
    final current = state;
    if (current is FiatPurchasesLoaded && refresh) {
      emit(current.copyWith(isRefreshing: true));
    } else if (current is! FiatPurchasesLoaded) {
      emit(FiatPurchasesLoading());
    }

    try {
      final result = await _getPurchases(_query);
      emit(FiatPurchasesLoaded(
        purchases: result.data,
        meta: result.meta,
        query: _query,
      ));
    } catch (e) {
      emit(FiatPurchasesError(e.toString()));
    }
  }

  Future<void> _onLoad(
    LoadFiatPurchasesEvent event,
    Emitter<FiatPurchasesState> emit,
  ) =>
      _fetch(emit, refresh: state is FiatPurchasesLoaded);

  Future<void> _onPageChanged(
    FiatPurchasesPageChangedEvent event,
    Emitter<FiatPurchasesState> emit,
  ) async {
    _query = _query.copyWith(page: event.page);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onFilterChanged(
    FiatPurchasesFilterChangedEvent event,
    Emitter<FiatPurchasesState> emit,
  ) async {
    _query = event.query.copyWith(page: 1);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onSearch(
    FiatPurchasesSearchEvent event,
    Emitter<FiatPurchasesState> emit,
  ) async {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      add(FiatPurchasesApplySearchEvent(event.search));
    });
  }

  Future<void> _onApplySearch(
    FiatPurchasesApplySearchEvent event,
    Emitter<FiatPurchasesState> emit,
  ) async {
    final trimmed = event.search.trim();
    _query = _query.copyWith(
      page: 1,
      search: trimmed.isEmpty ? null : trimmed,
      clearSearch: trimmed.isEmpty,
    );
    await _fetch(emit, refresh: true);
  }
}
