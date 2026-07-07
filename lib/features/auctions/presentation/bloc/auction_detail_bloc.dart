import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_update_body.dart';
import '../../domain/entities/auction_update_entity.dart';
import '../../domain/usecases/ban_auction_usecase.dart';
import '../../domain/usecases/cancel_auction_usecase.dart';
import '../../domain/usecases/get_auction_details_usecase.dart';
import '../../domain/usecases/preview_auction_pricing_usecase.dart';
import '../../domain/usecases/resolve_auction_usecase.dart';
import '../../domain/usecases/update_auction_usecase.dart';
import '../../data/datasources/auction_socket_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuctionDetailEvent {}

class LoadAuctionDetailsEvent extends AuctionDetailEvent {
  LoadAuctionDetailsEvent(this.auctionId);
  final String auctionId;
}

class JoinAuctionRoomEvent extends AuctionDetailEvent {
  JoinAuctionRoomEvent(this.auctionId);
  final String auctionId;
}

class LeaveAuctionRoomEvent extends AuctionDetailEvent {}

class ReceiveAuctionUpdateEvent extends AuctionDetailEvent {
  ReceiveAuctionUpdateEvent(this.update);
  final AuctionUpdateEntity update;
}

class AdminCancelDetailAuctionEvent extends AuctionDetailEvent {}

class AdminBanDetailAuctionEvent extends AuctionDetailEvent {}

class AdminUpdateAuctionEvent extends AuctionDetailEvent {
  AdminUpdateAuctionEvent(this.body);
  final AuctionUpdateBody body;
}

class AdminResolveAuctionEvent extends AuctionDetailEvent {
  AdminResolveAuctionEvent(this.winnerId);
  final String winnerId;
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuctionDetailState {}

class AuctionDetailInitial extends AuctionDetailState {}

class AuctionDetailLoading extends AuctionDetailState {}

class AuctionDetailLoaded extends AuctionDetailState {
  AuctionDetailLoaded({
    required this.auction,
    this.isLive = false,
    this.lastGiftName,
    this.lastGiftThumbnail,
    this.isActioning = false,
    this.successMessage,
    this.errorMessage,
  });

  final AuctionEntity auction;
  final bool isLive;
  final String? lastGiftName;
  final String? lastGiftThumbnail;
  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;

  AuctionDetailLoaded copyWith({
    AuctionEntity? auction,
    bool? isLive,
    String? lastGiftName,
    String? lastGiftThumbnail,
    bool? isActioning,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return AuctionDetailLoaded(
      auction: auction ?? this.auction,
      isLive: isLive ?? this.isLive,
      lastGiftName: lastGiftName ?? this.lastGiftName,
      lastGiftThumbnail: lastGiftThumbnail ?? this.lastGiftThumbnail,
      isActioning: isActioning ?? this.isActioning,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuctionDetailError extends AuctionDetailState {
  AuctionDetailError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class AuctionDetailBloc extends Bloc<AuctionDetailEvent, AuctionDetailState> {
  AuctionDetailBloc({
    required GetAuctionDetails getAuctionDetails,
    required AdminCancelAuction cancelAuction,
    required AdminBanAuction banAuction,
    required AdminUpdateAuction updateAuction,
    required AdminResolveAuction resolveAuction,
    required PreviewAuctionPricing previewPricing,
    required AuctionSocketService socketService,
  })  : _getAuctionDetails = getAuctionDetails,
        _cancelAuction = cancelAuction,
        _banAuction = banAuction,
        _updateAuction = updateAuction,
        _resolveAuction = resolveAuction,
        _previewPricing = previewPricing,
        _socketService = socketService,
        super(AuctionDetailInitial()) {
    on<LoadAuctionDetailsEvent>(_onLoad);
    on<JoinAuctionRoomEvent>(_onJoinRoom);
    on<LeaveAuctionRoomEvent>(_onLeaveRoom);
    on<ReceiveAuctionUpdateEvent>(_onReceiveUpdate);
    on<AdminCancelDetailAuctionEvent>(_onCancel);
    on<AdminBanDetailAuctionEvent>(_onBan);
    on<AdminUpdateAuctionEvent>(_onUpdate);
    on<AdminResolveAuctionEvent>(_onResolve);
  }

  final GetAuctionDetails _getAuctionDetails;
  final AdminCancelAuction _cancelAuction;
  final AdminBanAuction _banAuction;
  final AdminUpdateAuction _updateAuction;
  final AdminResolveAuction _resolveAuction;
  final PreviewAuctionPricing _previewPricing;
  final AuctionSocketService _socketService;
  StreamSubscription<AuctionUpdateEntity>? _socketSub;
  String? _currentAuctionId;

  Future<void> _onLoad(
      LoadAuctionDetailsEvent event, Emitter<AuctionDetailState> emit) async {
    emit(AuctionDetailLoading());
    try {
      final auction = await _getAuctionDetails(event.auctionId);
      emit(AuctionDetailLoaded(auction: auction, isLive: false));
      if (auction.isActive) {
        add(JoinAuctionRoomEvent(auction.id));
      }
    } catch (e) {
      emit(AuctionDetailError(e.toString()));
    }
  }

  Future<void> _onJoinRoom(
      JoinAuctionRoomEvent event, Emitter<AuctionDetailState> emit) async {
    _currentAuctionId = event.auctionId;
    _socketService.joinAuction(event.auctionId);
    await _socketSub?.cancel();
    _socketSub = _socketService.updates
        .where((u) => u.auctionId == event.auctionId)
        .listen((update) => add(ReceiveAuctionUpdateEvent(update)));

    final current = state;
    if (current is AuctionDetailLoaded) {
      emit(current.copyWith(isLive: true));
    }
  }

  void _onLeaveRoom(
      LeaveAuctionRoomEvent event, Emitter<AuctionDetailState> emit) {
    if (_currentAuctionId != null) {
      _socketService.leaveAuction(_currentAuctionId!);
      _currentAuctionId = null;
    }
    _socketSub?.cancel();
    _socketSub = null;
    final current = state;
    if (current is AuctionDetailLoaded) {
      emit(current.copyWith(isLive: false));
    }
  }

  void _onReceiveUpdate(
      ReceiveAuctionUpdateEvent event, Emitter<AuctionDetailState> emit) {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    final update = event.update;
    final updated = current.auction.copyWith(
      currentTotalCoins: update.currentTotalCoins,
      targetPriceCoins: update.targetPriceCoins,
      status: update.status,
      winnerId: update.winnerId,
      pricing: update.pricing ?? current.auction.pricing,
    );
    emit(current.copyWith(
      auction: updated,
      lastGiftName: update.lastGiftName,
      lastGiftThumbnail: update.lastGiftThumbnail,
      isLive: true,
    ));
  }

  Future<void> _onCancel(
      AdminCancelDetailAuctionEvent event, Emitter<AuctionDetailState> emit) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _cancelAuction(current.auction.id);
      final refreshed = await _getAuctionDetails(updated.id);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        isLive: false,
        successMessage: 'Auction cancelled successfully',
      ));
      add(LeaveAuctionRoomEvent());
    } catch (e) {
      emit(current.copyWith(
          isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onBan(
      AdminBanDetailAuctionEvent event, Emitter<AuctionDetailState> emit) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _banAuction(current.auction.id);
      final refreshed = await _getAuctionDetails(updated.id);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        isLive: false,
        successMessage: 'Auction banned',
      ));
      add(LeaveAuctionRoomEvent());
    } catch (e) {
      emit(current.copyWith(isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(
      AdminUpdateAuctionEvent event, Emitter<AuctionDetailState> emit) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    if (event.body.isEmpty) {
      emit(current.copyWith(errorMessage: 'No changes to save'));
      return;
    }
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      await _updateAuction(current.auction.id, event.body);
      var refreshed = await _getAuctionDetails(current.auction.id);
      refreshed = await _applyResolvedCoinGoal(refreshed, event.body);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        successMessage: 'Auction updated',
      ));
    } catch (e) {
      emit(current.copyWith(isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onResolve(
      AdminResolveAuctionEvent event, Emitter<AuctionDetailState> emit) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final resolved =
          await _resolveAuction(current.auction.id, event.winnerId);
      final refreshed = await _getAuctionDetails(resolved.id);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        isLive: false,
        successMessage: 'Auction resolved successfully',
      ));
      add(LeaveAuctionRoomEvent());
    } catch (e) {
      emit(current.copyWith(
          isActioning: false, errorMessage: e.toString()));
    }
  }

  Future<AuctionEntity> _applyResolvedCoinGoal(
    AuctionEntity auction,
    AuctionUpdateBody body,
  ) async {
    if (body.targetPrice == null && body.startingPrice == null) {
      return auction;
    }

    final moneyTarget = body.targetPrice ?? auction.targetPrice;
    if (moneyTarget == null || moneyTarget <= 0) return auction;

    try {
      final preview = await _previewPricing(targetPrice: moneyTarget);
      final resolved = preview.resolvedTargetPriceCoins;
      if (resolved != null && resolved > 0) {
        return auction.copyWith(targetPriceCoins: resolved);
      }
    } catch (_) {}

    return auction;
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();
    if (_currentAuctionId != null) {
      _socketService.leaveAuction(_currentAuctionId!);
    }
    return super.close();
  }
}
