import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class WithdrawalsEvent {}

class LoadWithdrawalsEvent extends WithdrawalsEvent {}

class WithdrawalsPageChangedEvent extends WithdrawalsEvent {
  WithdrawalsPageChangedEvent(this.page);
  final int page;
}

class WithdrawalsStatusFilterEvent extends WithdrawalsEvent {
  WithdrawalsStatusFilterEvent(this.status);
  final String? status;
}

abstract class WithdrawalsState {}

class WithdrawalsInitial extends WithdrawalsState {}

class WithdrawalsLoading extends WithdrawalsState {}

class WithdrawalsLoaded extends WithdrawalsState {
  WithdrawalsLoaded({
    required this.withdrawals,
    required this.meta,
    required this.query,
    this.isRefreshing = false,
  });

  final List<WithdrawalEntity> withdrawals;
  final PaginationMeta meta;
  final WithdrawalsQuery query;
  final bool isRefreshing;

  WithdrawalsLoaded copyWith({
    List<WithdrawalEntity>? withdrawals,
    PaginationMeta? meta,
    WithdrawalsQuery? query,
    bool? isRefreshing,
  }) {
    return WithdrawalsLoaded(
      withdrawals: withdrawals ?? this.withdrawals,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class WithdrawalsError extends WithdrawalsState {
  WithdrawalsError(this.message);
  final String message;
}

class WithdrawalsBloc extends Bloc<WithdrawalsEvent, WithdrawalsState> {
  WithdrawalsBloc({required GetWithdrawalsUseCase getWithdrawals})
      : _getWithdrawals = getWithdrawals,
        super(WithdrawalsInitial()) {
    on<LoadWithdrawalsEvent>(_onLoad);
    on<WithdrawalsPageChangedEvent>(_onPageChanged);
    on<WithdrawalsStatusFilterEvent>(_onStatusFilter);
  }

  final GetWithdrawalsUseCase _getWithdrawals;
  WithdrawalsQuery _query = const WithdrawalsQuery();

  Future<void> _fetch(
    Emitter<WithdrawalsState> emit, {
    bool refresh = false,
  }) async {
    final current = state;
    if (current is WithdrawalsLoaded && refresh) {
      emit(current.copyWith(isRefreshing: true));
    } else if (current is! WithdrawalsLoaded) {
      emit(WithdrawalsLoading());
    }

    try {
      final result = await _getWithdrawals(_query);
      emit(WithdrawalsLoaded(
        withdrawals: result.data,
        meta: result.meta,
        query: _query,
      ));
    } catch (e) {
      emit(WithdrawalsError(e.toString()));
    }
  }

  Future<void> _onLoad(
    LoadWithdrawalsEvent event,
    Emitter<WithdrawalsState> emit,
  ) =>
      _fetch(emit, refresh: state is WithdrawalsLoaded);

  Future<void> _onPageChanged(
    WithdrawalsPageChangedEvent event,
    Emitter<WithdrawalsState> emit,
  ) async {
    _query = _query.copyWith(page: event.page);
    await _fetch(emit, refresh: true);
  }

  Future<void> _onStatusFilter(
    WithdrawalsStatusFilterEvent event,
    Emitter<WithdrawalsState> emit,
  ) async {
    _query = _query.copyWith(
      page: 1,
      status: event.status,
      clearStatus: event.status == null,
    );
    await _fetch(emit, refresh: true);
  }
}
