import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_update_body.dart';
import '../../domain/entities/auction_update_entity.dart';
import '../../domain/usecases/admin_refund_fulfillment_usecase.dart';
import '../../domain/usecases/admin_release_fulfillment_usecase.dart';
import '../../domain/usecases/ban_auction_usecase.dart';
import '../../domain/usecases/cancel_auction_usecase.dart';
import '../../domain/usecases/get_auction_details_usecase.dart';
import '../../domain/usecases/preview_auction_pricing_usecase.dart';
import '../../domain/usecases/resolve_auction_usecase.dart';
import '../../domain/usecases/unban_auction_usecase.dart';
import '../../domain/usecases/update_auction_usecase.dart';
import '../../data/datasources/auction_socket_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuctionDetailEvent {}

class LoadAuctionDetailsEvent extends AuctionDetailEvent {
  LoadAuctionDetailsEvent(this.auctionId, {this.listPreview});

  final String auctionId;
  final AuctionEntity? listPreview;
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

class AdminUnbanDetailAuctionEvent extends AuctionDetailEvent {}

class AdminUpdateAuctionEvent extends AuctionDetailEvent {
  AdminUpdateAuctionEvent(this.body);
  final AuctionUpdateBody body;
}

class AdminResolveAuctionEvent extends AuctionDetailEvent {
  AdminResolveAuctionEvent(this.winnerId);
  final String winnerId;
}

class AdminRefundFulfillmentEvent extends AuctionDetailEvent {}

class AdminReleaseFulfillmentEvent extends AuctionDetailEvent {}

class ClearAuctionDetailMessagesEvent extends AuctionDetailEvent {}

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
    required AdminUnbanAuction unbanAuction,
    required AdminUpdateAuction updateAuction,
    required AdminResolveAuction resolveAuction,
    required AdminRefundFulfillment refundFulfillment,
    required AdminReleaseFulfillment releaseFulfillment,
    required PreviewAuctionPricing previewPricing,
    required AuctionSocketService socketService,
  })  : _getAuctionDetails = getAuctionDetails,
        _cancelAuction = cancelAuction,
        _banAuction = banAuction,
        _unbanAuction = unbanAuction,
        _updateAuction = updateAuction,
        _resolveAuction = resolveAuction,
        _refundFulfillment = refundFulfillment,
        _releaseFulfillment = releaseFulfillment,
        _previewPricing = previewPricing,
        _socketService = socketService,
        super(AuctionDetailInitial()) {
    on<LoadAuctionDetailsEvent>(_onLoad);
    on<JoinAuctionRoomEvent>(_onJoinRoom);
    on<LeaveAuctionRoomEvent>(_onLeaveRoom);
    on<ReceiveAuctionUpdateEvent>(_onReceiveUpdate);
    on<AdminCancelDetailAuctionEvent>(_onCancel);
    on<AdminBanDetailAuctionEvent>(_onBan);
    on<AdminUnbanDetailAuctionEvent>(_onUnban);
    on<AdminUpdateAuctionEvent>(_onUpdate);
    on<AdminResolveAuctionEvent>(_onResolve);
    on<AdminRefundFulfillmentEvent>(_onRefundFulfillment);
    on<AdminReleaseFulfillmentEvent>(_onReleaseFulfillment);
    on<ClearAuctionDetailMessagesEvent>(_onClearMessages);
  }

  final GetAuctionDetails _getAuctionDetails;
  final AdminCancelAuction _cancelAuction;
  final AdminBanAuction _banAuction;
  final AdminUnbanAuction _unbanAuction;
  final AdminUpdateAuction _updateAuction;
  final AdminResolveAuction _resolveAuction;
  final AdminRefundFulfillment _refundFulfillment;
  final AdminReleaseFulfillment _releaseFulfillment;
  final PreviewAuctionPricing _previewPricing;
  final AuctionSocketService _socketService;
  StreamSubscription<AuctionUpdateEntity>? _socketSub;
  String? _currentAuctionId;

  Future<void> _onLoad(
      LoadAuctionDetailsEvent event, Emitter<AuctionDetailState> emit) async {
    emit(AuctionDetailLoading());
    try {
      var auction = await _getAuctionDetails(event.auctionId);
      if (event.listPreview != null) {
        auction = auction.mergeAdminListPreview(event.listPreview!);
      }
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

  Future<void> _onUnban(
    AdminUnbanDetailAuctionEvent event,
    Emitter<AuctionDetailState> emit,
  ) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await _unbanAuction(current.auction.id);
      final refreshed = await _getAuctionDetails(updated.id);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        successMessage: 'auction_unbanned_successfully',
      ));
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
      var refreshed = await _updateAuction(current.auction.id, event.body);
      refreshed = await _applyResolvedCoinGoal(refreshed, event.body);
      final latest = state;
      if (latest is! AuctionDetailLoaded) return;
      emit(latest.copyWith(
        auction: refreshed,
        isActioning: false,
        successMessage: 'auction_updated_successfully',
      ));
    } catch (e) {
      final latest = state;
      if (latest is! AuctionDetailLoaded) return;
      emit(latest.copyWith(
        isActioning: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearMessages(
    ClearAuctionDetailMessagesEvent event,
    Emitter<AuctionDetailState> emit,
  ) {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(clearMessages: true));
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

  Future<void> _onRefundFulfillment(
    AdminRefundFulfillmentEvent event,
    Emitter<AuctionDetailState> emit,
  ) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final result = await _refundFulfillment(current.auction.id);
      final auctionId = result.auction.id.isNotEmpty
          ? result.auction.id
          : current.auction.id;
      final refreshed = await _getAuctionDetails(auctionId);
      final count = result.refundedCount;
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        isLive: false,
        successMessage: count != null
            ? 'auction_fulfillment_refund:$count'
            : 'auction_fulfillment_refund',
      ));
      add(LeaveAuctionRoomEvent());
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReleaseFulfillment(
    AdminReleaseFulfillmentEvent event,
    Emitter<AuctionDetailState> emit,
  ) async {
    final current = state;
    if (current is! AuctionDetailLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final result = await _releaseFulfillment(current.auction.id);
      final auctionId = result.auction.id.isNotEmpty
          ? result.auction.id
          : current.auction.id;
      final refreshed = await _getAuctionDetails(auctionId);
      emit(current.copyWith(
        auction: refreshed,
        isActioning: false,
        isLive: false,
        successMessage: result.alreadySettled
            ? 'auction_fulfillment_already_settled'
            : 'auction_fulfillment_release',
      ));
      add(LeaveAuctionRoomEvent());
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        errorMessage: e.toString(),
      ));
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
