import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sound_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

enum SoundCrudOperation {
  create,
  update,
  delete,
  activate,
  deactivate,
}

abstract class SoundCrudEvent extends Equatable {
  const SoundCrudEvent();
  @override
  List<Object?> get props => [];
}

class CreateSoundEvent extends SoundCrudEvent {
  const CreateSoundEvent(this.data);
  final CreateSoundData data;
  @override
  List<Object?> get props => [data];
}

class UploadSoundEvent extends SoundCrudEvent {
  const UploadSoundEvent(this.data);
  final UploadSoundData data;
  @override
  List<Object?> get props => [data];
}

class UpdateSoundEvent extends SoundCrudEvent {
  const UpdateSoundEvent({required this.soundId, required this.data});
  final String soundId;
  final UpdateSoundData data;
  @override
  List<Object?> get props => [soundId, data];
}

class DeleteSoundEvent extends SoundCrudEvent {
  const DeleteSoundEvent(this.soundId);
  final String soundId;
  @override
  List<Object?> get props => [soundId];
}

class ActivateSoundEvent extends SoundCrudEvent {
  const ActivateSoundEvent(this.soundId);
  final String soundId;
  @override
  List<Object?> get props => [soundId];
}

class DeactivateSoundEvent extends SoundCrudEvent {
  const DeactivateSoundEvent(this.soundId);
  final String soundId;
  @override
  List<Object?> get props => [soundId];
}

class ResetSoundCrudEvent extends SoundCrudEvent {
  const ResetSoundCrudEvent();
}

abstract class SoundCrudState extends Equatable {
  const SoundCrudState();
  @override
  List<Object?> get props => [];
}

class SoundCrudInitial extends SoundCrudState {}

class SoundCrudLoading extends SoundCrudState {
  const SoundCrudLoading(this.operation);
  final SoundCrudOperation operation;
  @override
  List<Object?> get props => [operation];
}

class SoundCrudSuccess extends SoundCrudState {
  const SoundCrudSuccess({
    required this.operation,
    this.sound,
    this.message,
  });

  final SoundCrudOperation operation;
  final SoundEntity? sound;
  final String? message;

  @override
  List<Object?> get props => [operation, sound, message];
}

class SoundCrudError extends SoundCrudState {
  const SoundCrudError({
    required this.operation,
    required this.message,
  });

  final SoundCrudOperation operation;
  final String message;

  @override
  List<Object?> get props => [operation, message];
}

class SoundCrudBloc extends Bloc<SoundCrudEvent, SoundCrudState> {
  SoundCrudBloc({
    required CreateSoundUseCase createSound,
    required UploadSoundUseCase uploadSound,
    required UpdateSoundUseCase updateSound,
    required DeleteSoundUseCase deleteSound,
    required ActivateSoundUseCase activateSound,
    required DeactivateSoundUseCase deactivateSound,
  })  : _createSound = createSound,
        _uploadSound = uploadSound,
        _updateSound = updateSound,
        _deleteSound = deleteSound,
        _activateSound = activateSound,
        _deactivateSound = deactivateSound,
        super(SoundCrudInitial()) {
    on<CreateSoundEvent>(_onCreate);
    on<UploadSoundEvent>(_onUpload);
    on<UpdateSoundEvent>(_onUpdate);
    on<DeleteSoundEvent>(_onDelete);
    on<ActivateSoundEvent>(_onActivate);
    on<DeactivateSoundEvent>(_onDeactivate);
    on<ResetSoundCrudEvent>((_, emit) => emit(SoundCrudInitial()));
  }

  final CreateSoundUseCase _createSound;
  final UploadSoundUseCase _uploadSound;
  final UpdateSoundUseCase _updateSound;
  final DeleteSoundUseCase _deleteSound;
  final ActivateSoundUseCase _activateSound;
  final DeactivateSoundUseCase _deactivateSound;

  Future<void> _onCreate(
    CreateSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.create));
    try {
      final sound = await _createSound(event.data);
      emit(SoundCrudSuccess(operation: SoundCrudOperation.create, sound: sound));
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.create,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUpload(
    UploadSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.create));
    try {
      final sound = await _uploadSound(event.data);
      emit(SoundCrudSuccess(operation: SoundCrudOperation.create, sound: sound));
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.create,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.update));
    try {
      final sound = await _updateSound(event.soundId, event.data);
      emit(SoundCrudSuccess(operation: SoundCrudOperation.update, sound: sound));
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.update,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    DeleteSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.delete));
    try {
      await _deleteSound(event.soundId);
      emit(const SoundCrudSuccess(operation: SoundCrudOperation.delete));
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.delete,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onActivate(
    ActivateSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.activate));
    try {
      final sound = await _activateSound(event.soundId);
      emit(
        SoundCrudSuccess(operation: SoundCrudOperation.activate, sound: sound),
      );
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.activate,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onDeactivate(
    DeactivateSoundEvent event,
    Emitter<SoundCrudState> emit,
  ) async {
    emit(const SoundCrudLoading(SoundCrudOperation.deactivate));
    try {
      final sound = await _deactivateSound(event.soundId);
      emit(
        SoundCrudSuccess(
          operation: SoundCrudOperation.deactivate,
          sound: sound,
        ),
      );
    } catch (e) {
      emit(SoundCrudError(
        operation: SoundCrudOperation.deactivate,
        message: e.toString(),
      ));
    }
  }
}
