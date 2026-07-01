import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/economy_setting_entity.dart';
import '../../domain/usecases/economy_setting_usecases.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class EconomySettingsEvent extends Equatable {
  const EconomySettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadEconomySettingsEvent extends EconomySettingsEvent {
  const LoadEconomySettingsEvent();
}

class UpdateEconomySettingEvent extends EconomySettingsEvent {
  const UpdateEconomySettingEvent({required this.key, required this.value});
  final String key;
  final String value;

  @override
  List<Object?> get props => [key, value];
}

// ─── State ───────────────────────────────────────────────────────────────────

class EconomySettingsState extends Equatable {
  const EconomySettingsState({
    this.commissionPercent,
    this.coinsPerPriceUnit,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.saveMessage,
  });

  final String? commissionPercent;
  final String? coinsPerPriceUnit;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? saveMessage;

  EconomySettingsState copyWith({
    String? commissionPercent,
    String? coinsPerPriceUnit,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? saveMessage,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return EconomySettingsState(
      commissionPercent: commissionPercent ?? this.commissionPercent,
      coinsPerPriceUnit: coinsPerPriceUnit ?? this.coinsPerPriceUnit,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      saveMessage: clearMessage ? null : (saveMessage ?? this.saveMessage),
    );
  }

  @override
  List<Object?> get props => [
        commissionPercent,
        coinsPerPriceUnit,
        isLoading,
        isSaving,
        error,
        saveMessage,
      ];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class EconomySettingsBloc
    extends Bloc<EconomySettingsEvent, EconomySettingsState> {
  EconomySettingsBloc({
    required GetEconomySettingUseCase getSetting,
    required UpdateEconomySettingUseCase updateSetting,
  })  : _getSetting = getSetting,
        _updateSetting = updateSetting,
        super(const EconomySettingsState()) {
    on<LoadEconomySettingsEvent>(_onLoad);
    on<UpdateEconomySettingEvent>(_onUpdate);
  }

  final GetEconomySettingUseCase _getSetting;
  final UpdateEconomySettingUseCase _updateSetting;

  Future<void> _onLoad(
    LoadEconomySettingsEvent event,
    Emitter<EconomySettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    try {
      final commission = await _getSetting(
        EconomySettingKeys.auctionCommissionPercent,
      );
      final coinsPerUnit = await _getSetting(
        EconomySettingKeys.coinsPerPriceUnit,
      );
      emit(
        state.copyWith(
          isLoading: false,
          commissionPercent: commission.value,
          coinsPerPriceUnit: coinsPerUnit.value,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateEconomySettingEvent event,
    Emitter<EconomySettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearMessage: true));
    try {
      final updated = await _updateSetting(event.key, event.value);
      if (event.key == EconomySettingKeys.auctionCommissionPercent) {
        emit(state.copyWith(
          isSaving: false,
          commissionPercent: updated.value,
          saveMessage: 'Setting saved',
        ));
      } else if (event.key == EconomySettingKeys.coinsPerPriceUnit) {
        emit(state.copyWith(
          isSaving: false,
          coinsPerPriceUnit: updated.value,
          saveMessage: 'Setting saved',
        ));
      } else {
        emit(state.copyWith(isSaving: false, saveMessage: 'Setting saved'));
      }
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }
}
