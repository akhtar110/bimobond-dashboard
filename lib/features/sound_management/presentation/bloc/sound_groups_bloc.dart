import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sound_group_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

abstract class SoundGroupsEvent extends Equatable {
  const SoundGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSoundGroupsEvent extends SoundGroupsEvent {
  const LoadSoundGroupsEvent({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

class CreateSoundGroupEvent extends SoundGroupsEvent {
  const CreateSoundGroupEvent(this.data);
  final CreateSoundGroupData data;
  @override
  List<Object?> get props => [data];
}

class UpdateSoundGroupEvent extends SoundGroupsEvent {
  const UpdateSoundGroupEvent({required this.groupId, required this.data});
  final String groupId;
  final UpdateSoundGroupData data;
  @override
  List<Object?> get props => [groupId, data];
}

class DeleteSoundGroupEvent extends SoundGroupsEvent {
  const DeleteSoundGroupEvent(this.groupId);
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}

class ReorderSoundGroupsEvent extends SoundGroupsEvent {
  const ReorderSoundGroupsEvent(this.items);
  final List<SoundGroupReorderItem> items;
  @override
  List<Object?> get props => [items];
}

class ReplaceGroupSoundsEvent extends SoundGroupsEvent {
  const ReplaceGroupSoundsEvent({
    required this.groupId,
    required this.sounds,
  });
  final String groupId;
  final List<SoundGroupMembershipItem> sounds;
  @override
  List<Object?> get props => [groupId, sounds];
}

class ClearSoundGroupsFeedbackEvent extends SoundGroupsEvent {
  const ClearSoundGroupsFeedbackEvent();
}

abstract class SoundGroupsState extends Equatable {
  const SoundGroupsState();
  @override
  List<Object?> get props => [];
}

class SoundGroupsInitial extends SoundGroupsState {}

class SoundGroupsLoading extends SoundGroupsState {}

class SoundGroupsLoaded extends SoundGroupsState {
  const SoundGroupsLoaded({
    required this.groups,
    this.isRefreshing = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<SoundGroupEntity> groups;
  final bool isRefreshing;
  final bool isMutating;
  final String? feedbackMessage;
  final bool feedbackIsError;

  SoundGroupsLoaded copyWith({
    List<SoundGroupEntity>? groups,
    bool? isRefreshing,
    bool? isMutating,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return SoundGroupsLoaded(
      groups: groups ?? this.groups,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props =>
      [groups, isRefreshing, isMutating, feedbackMessage, feedbackIsError];
}

class SoundGroupsError extends SoundGroupsState {
  const SoundGroupsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class SoundGroupsBloc extends Bloc<SoundGroupsEvent, SoundGroupsState> {
  SoundGroupsBloc({
    required GetSoundGroupsUseCase getGroups,
    required CreateSoundGroupUseCase createGroup,
    required UpdateSoundGroupUseCase updateGroup,
    required DeleteSoundGroupUseCase deleteGroup,
    required ReorderSoundGroupsUseCase reorderGroups,
    required ReplaceGroupSoundsUseCase replaceGroupSounds,
  })  : _getGroups = getGroups,
        _createGroup = createGroup,
        _updateGroup = updateGroup,
        _deleteGroup = deleteGroup,
        _reorderGroups = reorderGroups,
        _replaceGroupSounds = replaceGroupSounds,
        super(SoundGroupsInitial()) {
    on<LoadSoundGroupsEvent>(_onLoad);
    on<CreateSoundGroupEvent>(_onCreate);
    on<UpdateSoundGroupEvent>(_onUpdate);
    on<DeleteSoundGroupEvent>(_onDelete);
    on<ReorderSoundGroupsEvent>(_onReorder);
    on<ReplaceGroupSoundsEvent>(_onReplaceSounds);
    on<ClearSoundGroupsFeedbackEvent>(_onClearFeedback);
  }

  final GetSoundGroupsUseCase _getGroups;
  final CreateSoundGroupUseCase _createGroup;
  final UpdateSoundGroupUseCase _updateGroup;
  final DeleteSoundGroupUseCase _deleteGroup;
  final ReorderSoundGroupsUseCase _reorderGroups;
  final ReplaceGroupSoundsUseCase _replaceGroupSounds;

  Future<void> _onLoad(
    LoadSoundGroupsEvent event,
    Emitter<SoundGroupsState> emit,
  ) async {
    final current = state;
    if (current is SoundGroupsLoaded) {
      emit(current.copyWith(isRefreshing: true, clearFeedback: true));
    } else {
      emit(SoundGroupsLoading());
    }

    try {
      final groups = await _getGroups();
      emit(SoundGroupsLoaded(groups: groups));
    } catch (e) {
      if (current is SoundGroupsLoaded) {
        emit(
          current.copyWith(
            isRefreshing: false,
            feedbackMessage: e.toString(),
            feedbackIsError: true,
          ),
        );
      } else {
        emit(SoundGroupsError(e.toString()));
      }
    }
  }

  Future<void> _mutate(
    Emitter<SoundGroupsState> emit,
    Future<void> Function() action, {
    required String successKey,
  }) async {
    final current = state;
    if (current is! SoundGroupsLoaded) return;
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      await action();
      final groups = await _getGroups();
      emit(
        SoundGroupsLoaded(
          groups: groups,
          feedbackMessage: successKey,
          feedbackIsError: false,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: e.toString(),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onCreate(
    CreateSoundGroupEvent event,
    Emitter<SoundGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _createGroup(event.data),
        successKey: 'soundGroupCreatedSuccess',
      );

  Future<void> _onUpdate(
    UpdateSoundGroupEvent event,
    Emitter<SoundGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _updateGroup(event.groupId, event.data),
        successKey: 'soundGroupUpdatedSuccess',
      );

  Future<void> _onDelete(
    DeleteSoundGroupEvent event,
    Emitter<SoundGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _deleteGroup(event.groupId),
        successKey: 'soundGroupDeletedSuccess',
      );

  Future<void> _onReorder(
    ReorderSoundGroupsEvent event,
    Emitter<SoundGroupsState> emit,
  ) async {
    final current = state;
    if (current is! SoundGroupsLoaded) return;
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      final groups = await _reorderGroups(event.items);
      emit(
        SoundGroupsLoaded(
          groups: groups,
          feedbackMessage: 'soundGroupReorderedSuccess',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: e.toString(),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onReplaceSounds(
    ReplaceGroupSoundsEvent event,
    Emitter<SoundGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _replaceGroupSounds(event.groupId, event.sounds),
        successKey: 'soundGroupSoundsUpdatedSuccess',
      );

  void _onClearFeedback(
    ClearSoundGroupsFeedbackEvent event,
    Emitter<SoundGroupsState> emit,
  ) {
    final current = state;
    if (current is SoundGroupsLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }
}
