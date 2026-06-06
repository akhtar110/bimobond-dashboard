import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auction_entity.dart';
import '../../domain/usecases/cancel_auction_usecase.dart';
import '../../domain/usecases/get_all_auctions_usecase.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuctionsEvent {}

class LoadAllAuctionsEvent extends AuctionsEvent {}

class FilterAuctionsEvent extends AuctionsEvent {
  FilterAuctionsEvent(this.status);
  final String? status; // null = all
}

class AdminCancelAuctionFromListEvent extends AuctionsEvent {
  AdminCancelAuctionFromListEvent(this.auctionId);
  final String auctionId;
}

/// Replaces a single auction in the loaded list without reloading everything.
/// Emitted by [AuctionDetailPage] after a cancel / resolve / socket update.
class AuctionStatusUpdatedEvent extends AuctionsEvent {
  AuctionStatusUpdatedEvent(this.auction);
  final AuctionEntity auction;
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuctionsState {}

class AuctionsInitial extends AuctionsState {}

class AuctionsLoading extends AuctionsState {}

class AuctionsLoaded extends AuctionsState {
  AuctionsLoaded({
    required this.allAuctions,
    this.filter,
    this.isActioning = false,
  });

  final List<AuctionEntity> allAuctions;
  final String? filter;
  final bool isActioning;

  List<AuctionEntity> get displayed => filter == null || filter!.isEmpty
      ? allAuctions
      : allAuctions.where((a) => a.status == filter).toList();

  int get activeCount =>
      allAuctions.where((a) => a.status == 'ACTIVE').length;
  int get completedCount =>
      allAuctions.where((a) => a.status == 'COMPLETED').length;
  int get cancelledCount =>
      allAuctions.where((a) => a.status == 'CANCELLED').length;

  AuctionsLoaded copyWith({
    List<AuctionEntity>? allAuctions,
    String? filter,
    bool clearFilter = false,
    bool? isActioning,
  }) {
    return AuctionsLoaded(
      allAuctions: allAuctions ?? this.allAuctions,
      filter: clearFilter ? null : (filter ?? this.filter),
      isActioning: isActioning ?? this.isActioning,
    );
  }
}

class AuctionsError extends AuctionsState {
  AuctionsError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class AuctionsBloc extends Bloc<AuctionsEvent, AuctionsState> {
  AuctionsBloc({
    required GetAllAuctions getAllAuctions,
    required AdminCancelAuction cancelAuction,
  })  : _getAllAuctions = getAllAuctions,
        _cancelAuction = cancelAuction,
        super(AuctionsInitial()) {
    on<LoadAllAuctionsEvent>(_onLoad);
    on<FilterAuctionsEvent>(_onFilter);
    on<AdminCancelAuctionFromListEvent>(_onCancel);
    on<AuctionStatusUpdatedEvent>(_onStatusUpdated);
  }

  final GetAllAuctions _getAllAuctions;
  final AdminCancelAuction _cancelAuction;

  Future<void> _onLoad(
      LoadAllAuctionsEvent event, Emitter<AuctionsState> emit) async {
    emit(AuctionsLoading());
    try {
      final auctions = await _getAllAuctions();
      emit(AuctionsLoaded(allAuctions: auctions));
    } catch (e) {
      emit(AuctionsError(e.toString()));
    }
  }

  void _onFilter(FilterAuctionsEvent event, Emitter<AuctionsState> emit) {
    final current = state;
    if (current is AuctionsLoaded) {
      emit(current.copyWith(
        filter: event.status,
        clearFilter: event.status == null,
      ));
    }
  }

  Future<void> _onCancel(
      AdminCancelAuctionFromListEvent event, Emitter<AuctionsState> emit) async {
    final current = state;
    if (current is! AuctionsLoaded) return;
    emit(current.copyWith(isActioning: true));
    try {
      await _cancelAuction(event.auctionId);
      final updated = current.allAuctions.map((a) {
        if (a.id == event.auctionId) {
          return a.copyWith(status: 'CANCELLED', endedAt: DateTime.now());
        }
        return a;
      }).toList();
      emit(current.copyWith(allAuctions: updated, isActioning: false));
    } catch (e) {
      emit(current.copyWith(isActioning: false));
    }
  }

  /// Replaces a single auction by id without touching the rest of the list.
  /// Counts and filtered view are recalculated automatically via getters.
  void _onStatusUpdated(
      AuctionStatusUpdatedEvent event, Emitter<AuctionsState> emit) {
    final current = state;
    if (current is! AuctionsLoaded) return;

    final idx = current.allAuctions.indexWhere((a) => a.id == event.auction.id);
    if (idx == -1) return; // auction not in list yet — ignore

    final updated = List<AuctionEntity>.from(current.allAuctions);
    updated[idx] = event.auction;
    emit(current.copyWith(allAuctions: updated));
  }
}
