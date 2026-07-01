import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_setting_entity.dart';
import '../../domain/usecases/app_setting_usecases.dart';

abstract class AppSettingsEvent extends Equatable {
  const AppSettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAppSettingsEvent extends AppSettingsEvent {
  const LoadAppSettingsEvent();
}

class CreateAppSettingEvent extends AppSettingsEvent {
  const CreateAppSettingEvent(this.setting);
  final AppSettingEntity setting;

  @override
  List<Object?> get props => [setting];
}

class UpdateAppSettingEvent extends AppSettingsEvent {
  const UpdateAppSettingEvent(this.setting);
  final AppSettingEntity setting;

  @override
  List<Object?> get props => [setting];
}

class DeleteAppSettingEvent extends AppSettingsEvent {
  const DeleteAppSettingEvent(this.key);
  final String key;

  @override
  List<Object?> get props => [key];
}

class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.settings = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.message,
  });

  final List<AppSettingEntity> settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? message;

  AppSettingsState copyWith({
    List<AppSettingEntity>? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, isSaving, error, message];
}

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  AppSettingsBloc({
    required ListAppSettingsUseCase listSettings,
    required CreateAppSettingUseCase createSetting,
    required UpdateAppSettingUseCase updateSetting,
    required DeleteAppSettingUseCase deleteSetting,
  })  : _listSettings = listSettings,
        _createSetting = createSetting,
        _updateSetting = updateSetting,
        _deleteSetting = deleteSetting,
        super(const AppSettingsState()) {
    on<LoadAppSettingsEvent>(_onLoad);
    on<CreateAppSettingEvent>(_onCreate);
    on<UpdateAppSettingEvent>(_onUpdate);
    on<DeleteAppSettingEvent>(_onDelete);
  }

  final ListAppSettingsUseCase _listSettings;
  final CreateAppSettingUseCase _createSetting;
  final UpdateAppSettingUseCase _updateSetting;
  final DeleteAppSettingUseCase _deleteSetting;

  Future<void> _onLoad(
    LoadAppSettingsEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    try {
      final settings = await _listSettings();
      emit(state.copyWith(isLoading: false, settings: settings));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateAppSettingEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearMessage: true));
    try {
      final created = await _createSetting(event.setting);
      emit(
        state.copyWith(
          isSaving: false,
          settings: [...state.settings, created],
          message: 'Setting created',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateAppSettingEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearMessage: true));
    try {
      final updated = await _updateSetting(event.setting);
      final next = [
        for (final item in state.settings)
          if (item.key == updated.key) updated else item,
      ];
      emit(
        state.copyWith(
          isSaving: false,
          settings: next,
          message: 'Setting updated',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteAppSettingEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearMessage: true));
    try {
      await _deleteSetting(event.key);
      emit(
        state.copyWith(
          isSaving: false,
          settings:
              state.settings.where((s) => s.key != event.key).toList(),
          message: 'Setting deleted',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }
}
