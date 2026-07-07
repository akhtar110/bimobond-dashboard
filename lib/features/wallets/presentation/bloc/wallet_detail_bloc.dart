import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class WalletDetailEvent {}

class LoadWalletDetailEvent extends WalletDetailEvent {
  LoadWalletDetailEvent(this.userId);
  final String userId;
}

class AdjustWalletBalanceEvent extends WalletDetailEvent {
  AdjustWalletBalanceEvent(this.data);
  final AdjustBalanceData data;
}

abstract class WalletDetailState {}

class WalletDetailInitial extends WalletDetailState {}

class WalletDetailLoading extends WalletDetailState {}

class WalletDetailLoaded extends WalletDetailState {
  WalletDetailLoaded({
    required this.detail,
    this.isAdjusting = false,
    this.message,
    this.isError = false,
  });

  final WalletDetailEntity detail;
  final bool isAdjusting;
  final String? message;
  final bool isError;

  WalletDetailLoaded copyWith({
    WalletDetailEntity? detail,
    bool? isAdjusting,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return WalletDetailLoaded(
      detail: detail ?? this.detail,
      isAdjusting: isAdjusting ?? this.isAdjusting,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }
}

class WalletDetailError extends WalletDetailState {
  WalletDetailError(this.message);
  final String message;
}

class WalletDetailBloc extends Bloc<WalletDetailEvent, WalletDetailState> {
  WalletDetailBloc({
    required GetWalletDetailUseCase getDetail,
    required AdjustWalletBalanceUseCase adjustBalance,
  })  : _getDetail = getDetail,
        _adjustBalance = adjustBalance,
        super(WalletDetailInitial()) {
    on<LoadWalletDetailEvent>(_onLoad);
    on<AdjustWalletBalanceEvent>(_onAdjust);
  }

  final GetWalletDetailUseCase _getDetail;
  final AdjustWalletBalanceUseCase _adjustBalance;
  String? _userId;

  Future<void> _onLoad(
    LoadWalletDetailEvent event,
    Emitter<WalletDetailState> emit,
  ) async {
    _userId = event.userId;
    emit(WalletDetailLoading());
    try {
      final detail = await _getDetail(event.userId);
      emit(WalletDetailLoaded(detail: detail));
    } catch (e) {
      emit(WalletDetailError(e.toString()));
    }
  }

  Future<void> _onAdjust(
    AdjustWalletBalanceEvent event,
    Emitter<WalletDetailState> emit,
  ) async {
    final current = state;
    if (current is! WalletDetailLoaded || _userId == null) return;

    emit(current.copyWith(isAdjusting: true, clearMessage: true));
    try {
      final result = await _adjustBalance(_userId!, event.data);
      final detail = await _getDetail(_userId!);
      emit(WalletDetailLoaded(
        detail: detail,
        message: 'Balance updated to ${result.newBalanceCoins} coins',
      ));
    } catch (e) {
      emit(current.copyWith(
        isAdjusting: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }
}
