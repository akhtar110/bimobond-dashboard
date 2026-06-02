import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_entity.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/create_gift_usecase.dart';
import '../../domain/usecases/delete_gift_usecase.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';
import '../../domain/usecases/update_gift_usecase.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class GiftsEvent {}

class LoadAdminGiftsEvent extends GiftsEvent {}

class CreateGiftEvent extends GiftsEvent {
  CreateGiftEvent(this.data);
  final CreateGiftData data;
}

class UpdateGiftEvent extends GiftsEvent {
  UpdateGiftEvent(this.giftId, this.data);
  final String giftId;
  final UpdateGiftData data;
}

class ToggleGiftActiveEvent extends GiftsEvent {
  ToggleGiftActiveEvent(this.giftId, this.isActive);
  final String giftId;
  final bool isActive;
}

class DeleteGiftEvent extends GiftsEvent {
  DeleteGiftEvent(this.giftId);
  final String giftId;
}

class ToggleGiftsFilterEvent extends GiftsEvent {
  ToggleGiftsFilterEvent(this.showInactiveOnly);
  final bool showInactiveOnly;
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class GiftsState {}

class GiftsInitial extends GiftsState {}

class GiftsLoading extends GiftsState {}

class GiftsLoaded extends GiftsState {
  GiftsLoaded({
    required this.gifts,
    this.showInactiveOnly = false,
    this.isActioning = false,
    this.successMessage,
    this.errorMessage,
  });

  final List<GiftEntity> gifts;
  final bool showInactiveOnly;
  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;

  List<GiftEntity> get displayed =>
      showInactiveOnly ? gifts.where((g) => !g.isActive).toList() : gifts;

  GiftsLoaded copyWith({
    List<GiftEntity>? gifts,
    bool? showInactiveOnly,
    bool? isActioning,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return GiftsLoaded(
      gifts: gifts ?? this.gifts,
      showInactiveOnly: showInactiveOnly ?? this.showInactiveOnly,
      isActioning: isActioning ?? this.isActioning,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GiftsError extends GiftsState {
  GiftsError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class GiftsBloc extends Bloc<GiftsEvent, GiftsState> {
  GiftsBloc({
    required GetAdminGifts getAdminGifts,
    required CreateGift createGift,
    required UpdateGift updateGift,
    required DeleteGift deleteGift,
  })  : _getAdminGifts = getAdminGifts,
        _createGift = createGift,
        _updateGift = updateGift,
        _deleteGift = deleteGift,
        super(GiftsInitial()) {
    on<LoadAdminGiftsEvent>(_onLoad);
    on<CreateGiftEvent>(_onCreate);
    on<UpdateGiftEvent>(_onUpdate);
    on<ToggleGiftActiveEvent>(_onToggleActive);
    on<DeleteGiftEvent>(_onDelete);
    on<ToggleGiftsFilterEvent>(_onToggleFilter);
  }

  final GetAdminGifts _getAdminGifts;
  final CreateGift _createGift;
  final UpdateGift _updateGift;
  final DeleteGift _deleteGift;

  Future<void> _onLoad(
      LoadAdminGiftsEvent event, Emitter<GiftsState> emit) async {
    emit(GiftsLoading());
    try {
      final gifts = await _getAdminGifts();
      emit(GiftsLoaded(gifts: gifts));
    } catch (e) {
      emit(GiftsError(e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateGiftEvent event, Emitter<GiftsState> emit) async {
    final current = state;
    if (current is! GiftsLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final gift = await _createGift(event.data);
      emit(current.copyWith(
        gifts: [...current.gifts, gift],
        isActioning: false,
        successMessage: 'Gift "${gift.name}" created successfully',
      ));
    } catch (e) {
      emit(current.copyWith(
          isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateGiftEvent event, Emitter<GiftsState> emit) async {
    final current = state;
    if (current is! GiftsLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _updateGift(event.giftId, event.data);
      final gifts = current.gifts.map((g) => g.id == event.giftId ? updated : g).toList();
      emit(current.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift updated successfully',
      ));
    } catch (e) {
      emit(current.copyWith(
          isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleActive(
      ToggleGiftActiveEvent event, Emitter<GiftsState> emit) async {
    final current = state;
    if (current is! GiftsLoaded) return;
    try {
      final updated = await _updateGift(
          event.giftId, UpdateGiftData(isActive: event.isActive));
      final gifts =
          current.gifts.map((g) => g.id == event.giftId ? updated : g).toList();
      emit(current.copyWith(gifts: gifts));
    } catch (e) {
      emit(current.copyWith(errorMessage: e.toString()));
    }
  }

  void _onToggleFilter(
      ToggleGiftsFilterEvent event, Emitter<GiftsState> emit) {
    final current = state;
    if (current is GiftsLoaded) {
      emit(current.copyWith(showInactiveOnly: event.showInactiveOnly));
    }
  }

  Future<void> _onDelete(
      DeleteGiftEvent event, Emitter<GiftsState> emit) async {
    final current = state;
    if (current is! GiftsLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      await _deleteGift(event.giftId);
      final gifts = current.gifts.where((g) => g.id != event.giftId).toList();
      emit(current.copyWith(
        gifts: gifts,
        isActioning: false,
        successMessage: 'Gift deleted successfully',
      ));
    } catch (e) {
      emit(current.copyWith(
          isActioning: false, errorMessage: e.toString()));
    }
  }
}
