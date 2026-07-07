import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class EconomyEvent {}

class LoadEconomyEvent extends EconomyEvent {}

abstract class EconomyState {}

class EconomyInitial extends EconomyState {}

class EconomyLoading extends EconomyState {}

class EconomyLoaded extends EconomyState {
  EconomyLoaded(this.economy);
  final EconomyEntity economy;
}

class EconomyError extends EconomyState {
  EconomyError(this.message);
  final String message;
}

class EconomyBloc extends Bloc<EconomyEvent, EconomyState> {
  EconomyBloc({required GetEconomyUseCase getEconomy})
      : _getEconomy = getEconomy,
        super(EconomyInitial()) {
    on<LoadEconomyEvent>(_onLoad);
  }

  final GetEconomyUseCase _getEconomy;

  Future<void> _onLoad(
    LoadEconomyEvent event,
    Emitter<EconomyState> emit,
  ) async {
    emit(EconomyLoading());
    try {
      final economy = await _getEconomy();
      emit(EconomyLoaded(economy));
    } catch (e) {
      emit(EconomyError(e.toString()));
    }
  }
}
