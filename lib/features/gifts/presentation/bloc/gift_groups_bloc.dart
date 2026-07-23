import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_group_entities.dart';
import '../../domain/usecases/gift_group_usecases.dart';

abstract class GiftGroupsEvent extends Equatable {
  const GiftGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadGiftGroupsEvent extends GiftGroupsEvent {
  const LoadGiftGroupsEvent({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

class CreateGiftGroupEvent extends GiftGroupsEvent {
  const CreateGiftGroupEvent(this.data);
  final CreateGiftGroupData data;
  @override
  List<Object?> get props => [data];
}

class UpdateGiftGroupEvent extends GiftGroupsEvent {
  const UpdateGiftGroupEvent({required this.groupId, required this.data});
  final String groupId;
  final UpdateGiftGroupData data;
  @override
  List<Object?> get props => [groupId, data];
}

class DeleteGiftGroupEvent extends GiftGroupsEvent {
  const DeleteGiftGroupEvent(this.groupId);
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}

class ReorderGiftGroupsEvent extends GiftGroupsEvent {
  const ReorderGiftGroupsEvent(this.items);
  final List<GiftGroupReorderItem> items;
  @override
  List<Object?> get props => [items];
}

class ReplaceGroupGiftsEvent extends GiftGroupsEvent {
  const ReplaceGroupGiftsEvent({
    required this.groupId,
    required this.gifts,
  });
  final String groupId;
  final List<GiftGroupMembershipItem> gifts;
  @override
  List<Object?> get props => [groupId, gifts];
}

class ClearGiftGroupsFeedbackEvent extends GiftGroupsEvent {
  const ClearGiftGroupsFeedbackEvent();
}

abstract class GiftGroupsState extends Equatable {
  const GiftGroupsState();
  @override
  List<Object?> get props => [];
}

class GiftGroupsInitial extends GiftGroupsState {}

class GiftGroupsLoading extends GiftGroupsState {}

class GiftGroupsLoaded extends GiftGroupsState {
  const GiftGroupsLoaded({
    required this.groups,
    this.isRefreshing = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<GiftGroupEntity> groups;
  final bool isRefreshing;
  final bool isMutating;
  final String? feedbackMessage;
  final bool feedbackIsError;

  GiftGroupsLoaded copyWith({
    List<GiftGroupEntity>? groups,
    bool? isRefreshing,
    bool? isMutating,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return GiftGroupsLoaded(
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

class GiftGroupsError extends GiftGroupsState {
  const GiftGroupsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class GiftGroupsBloc extends Bloc<GiftGroupsEvent, GiftGroupsState> {
  GiftGroupsBloc({
    required GetGiftGroupsUseCase getGroups,
    required CreateGiftGroupUseCase createGroup,
    required UpdateGiftGroupUseCase updateGroup,
    required DeleteGiftGroupUseCase deleteGroup,
    required ReorderGiftGroupsUseCase reorderGroups,
    required ReplaceGroupGiftsUseCase replaceGroupGifts,
  })  : _getGroups = getGroups,
        _createGroup = createGroup,
        _updateGroup = updateGroup,
        _deleteGroup = deleteGroup,
        _reorderGroups = reorderGroups,
        _replaceGroupGifts = replaceGroupGifts,
        super(GiftGroupsInitial()) {
    on<LoadGiftGroupsEvent>(_onLoad);
    on<CreateGiftGroupEvent>(_onCreate);
    on<UpdateGiftGroupEvent>(_onUpdate);
    on<DeleteGiftGroupEvent>(_onDelete);
    on<ReorderGiftGroupsEvent>(_onReorder);
    on<ReplaceGroupGiftsEvent>(_onReplaceGifts);
    on<ClearGiftGroupsFeedbackEvent>(_onClearFeedback);
  }

  final GetGiftGroupsUseCase _getGroups;
  final CreateGiftGroupUseCase _createGroup;
  final UpdateGiftGroupUseCase _updateGroup;
  final DeleteGiftGroupUseCase _deleteGroup;
  final ReorderGiftGroupsUseCase _reorderGroups;
  final ReplaceGroupGiftsUseCase _replaceGroupGifts;

  Future<void> _onLoad(
    LoadGiftGroupsEvent event,
    Emitter<GiftGroupsState> emit,
  ) async {
    final current = state;
    if (current is GiftGroupsLoaded) {
      emit(current.copyWith(isRefreshing: true, clearFeedback: true));
    } else {
      emit(GiftGroupsLoading());
    }

    try {
      final groups = await _getGroups();
      emit(GiftGroupsLoaded(groups: groups));
    } catch (e) {
      if (current is GiftGroupsLoaded) {
        emit(
          current.copyWith(
            isRefreshing: false,
            feedbackMessage: e.toString(),
            feedbackIsError: true,
          ),
        );
      } else {
        emit(GiftGroupsError(e.toString()));
      }
    }
  }

  Future<void> _mutate(
    Emitter<GiftGroupsState> emit,
    Future<void> Function() action, {
    required String successKey,
  }) async {
    final current = state;
    if (current is! GiftGroupsLoaded) return;
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      await action();
      final groups = await _getGroups();
      emit(
        GiftGroupsLoaded(
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
    CreateGiftGroupEvent event,
    Emitter<GiftGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _createGroup(event.data),
        successKey: 'giftGroupCreatedSuccess',
      );

  Future<void> _onUpdate(
    UpdateGiftGroupEvent event,
    Emitter<GiftGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _updateGroup(event.groupId, event.data),
        successKey: 'giftGroupUpdatedSuccess',
      );

  Future<void> _onDelete(
    DeleteGiftGroupEvent event,
    Emitter<GiftGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _deleteGroup(event.groupId),
        successKey: 'giftGroupDeletedSuccess',
      );

  Future<void> _onReorder(
    ReorderGiftGroupsEvent event,
    Emitter<GiftGroupsState> emit,
  ) async {
    final current = state;
    if (current is! GiftGroupsLoaded) return;
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      final groups = await _reorderGroups(event.items);
      emit(
        GiftGroupsLoaded(
          groups: groups,
          feedbackMessage: 'giftGroupReorderedSuccess',
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

  Future<void> _onReplaceGifts(
    ReplaceGroupGiftsEvent event,
    Emitter<GiftGroupsState> emit,
  ) =>
      _mutate(
        emit,
        () => _replaceGroupGifts(event.groupId, event.gifts),
        successKey: 'giftGroupGiftsUpdatedSuccess',
      );

  void _onClearFeedback(
    ClearGiftGroupsFeedbackEvent event,
    Emitter<GiftGroupsState> emit,
  ) {
    final current = state;
    if (current is GiftGroupsLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }
}
