import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class LedgerEvent {}

class LoadLedgerEvent extends LedgerEvent {}

class LedgerPageChangedEvent extends LedgerEvent {
  LedgerPageChangedEvent(this.page);
  final int page;
}

class LedgerFilterChangedEvent extends LedgerEvent {
  LedgerFilterChangedEvent(this.query);
  final LedgerQuery query;
}

abstract class LedgerState {}

class LedgerInitial extends LedgerState {}

class LedgerLoading extends LedgerState {}

class LedgerLoaded extends LedgerState {
  LedgerLoaded({
    required this.entries,
    required this.meta,
    required this.query,
    this.isRefreshing = false,
  });

  final List<LedgerEntryEntity> entries;
  final PaginationMeta meta;
  final LedgerQuery query;
  final bool isRefreshing;

  LedgerLoaded copyWith({
    List<LedgerEntryEntity>? entries,
    PaginationMeta? meta,
    LedgerQuery? query,
    bool? isRefreshing,
  }) {
    return LedgerLoaded(
      entries: entries ?? this.entries,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class LedgerError extends LedgerState {
  LedgerError(this.message);
  final String message;
}

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc({required GetLedgerUseCase getLedger})
      : _getLedger = getLedger,
        super(LedgerInitial()) {
    on<LoadLedgerEvent>(_onLoad);
    on<LedgerPageChangedEvent>(_onPageChanged);
    on<LedgerFilterChangedEvent>(_onFilterChanged);
  }

  final GetLedgerUseCase _getLedger;
  LedgerQuery _query = const LedgerQuery();

  Future<void> _fetch(Emitter<LedgerState> emit, {bool refresh = false}) async {
    final current = state;
    if (current is LedgerLoaded && refresh) {
      emit(current.copyWith(isRefreshing: true));
    } else if (current is! LedgerLoaded) {
      emit(LedgerLoading());
    }

    try {
      final result = await _getLedger(_query);
      emit(LedgerLoaded(
        entries: result.data,
        meta: result.meta,
        query: _query,
      ));
    } catch (e) {
      emit(LedgerError(e.toString()));
    }
  }

  Future<void> _onLoad(LoadLedgerEvent event, Emitter<LedgerState> emit) =>
      _fetch(emit, refresh: state is LedgerLoaded);

  Future<void> _onPageChanged(
    LedgerPageChangedEvent event,
    Emitter<LedgerState> emit,
  ) async {
    _query = _query.copyWith(page: event.page);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onFilterChanged(
    LedgerFilterChangedEvent event,
    Emitter<LedgerState> emit,
  ) async {
    _query = event.query.copyWith(page: 1);
    await _fetch(emit, refresh: true);
  }
}
