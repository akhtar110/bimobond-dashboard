import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sound_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

abstract class BulkSoundActionEvent extends Equatable {
  const BulkSoundActionEvent();
  @override
  List<Object?> get props => [];
}

class ExecuteBulkSoundActionEvent extends BulkSoundActionEvent {
  const ExecuteBulkSoundActionEvent({
    required this.soundIds,
    required this.action,
  });

  final List<String> soundIds;
  final BulkSoundActionType action;

  @override
  List<Object?> get props => [soundIds, action];
}

abstract class BulkSoundActionState extends Equatable {
  const BulkSoundActionState();
  @override
  List<Object?> get props => [];
}

class BulkSoundActionInitial extends BulkSoundActionState {}

class BulkSoundActionRunning extends BulkSoundActionState {}

class BulkSoundActionSuccess extends BulkSoundActionState {
  const BulkSoundActionSuccess(this.result);
  final BulkSoundActionResultEntity result;
  @override
  List<Object?> get props => [result];
}

class BulkSoundActionError extends BulkSoundActionState {
  const BulkSoundActionError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class BulkSoundActionBloc
    extends Bloc<BulkSoundActionEvent, BulkSoundActionState> {
  BulkSoundActionBloc({required BulkSoundActionUseCase bulkAction})
      : _bulkAction = bulkAction,
        super(BulkSoundActionInitial()) {
    on<ExecuteBulkSoundActionEvent>(_onExecute);
  }

  final BulkSoundActionUseCase _bulkAction;

  Future<void> _onExecute(
    ExecuteBulkSoundActionEvent event,
    Emitter<BulkSoundActionState> emit,
  ) async {
    emit(BulkSoundActionRunning());
    try {
      final result = await _bulkAction(
        BulkSoundActionRequest(
          soundIds: event.soundIds,
          action: event.action,
        ),
      );
      emit(BulkSoundActionSuccess(result));
    } catch (e) {
      emit(BulkSoundActionError(e.toString()));
    }
  }
}
