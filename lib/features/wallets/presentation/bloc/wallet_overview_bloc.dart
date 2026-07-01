import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class WalletOverviewEvent {}

class LoadWalletOverviewEvent extends WalletOverviewEvent {}

abstract class WalletOverviewState {}

class WalletOverviewInitial extends WalletOverviewState {}

class WalletOverviewLoading extends WalletOverviewState {}

class WalletOverviewLoaded extends WalletOverviewState {
  WalletOverviewLoaded(this.overview);
  final WalletOverviewEntity overview;
}

class WalletOverviewError extends WalletOverviewState {
  WalletOverviewError(this.message);
  final String message;
}

class WalletOverviewBloc extends Bloc<WalletOverviewEvent, WalletOverviewState> {
  WalletOverviewBloc({required GetWalletOverviewUseCase getOverview})
      : _getOverview = getOverview,
        super(WalletOverviewInitial()) {
    on<LoadWalletOverviewEvent>(_onLoad);
  }

  final GetWalletOverviewUseCase _getOverview;

  Future<void> _onLoad(
    LoadWalletOverviewEvent event,
    Emitter<WalletOverviewState> emit,
  ) async {
    emit(WalletOverviewLoading());
    try {
      final overview = await _getOverview();
      emit(WalletOverviewLoaded(overview));
    } catch (e) {
      emit(WalletOverviewError(e.toString()));
    }
  }
}
