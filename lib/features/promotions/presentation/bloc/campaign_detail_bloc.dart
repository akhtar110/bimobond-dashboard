import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/usecases/promotion_usecases.dart';

abstract class CampaignDetailEvent {}

class LoadCampaignDetailEvent extends CampaignDetailEvent {
  LoadCampaignDetailEvent(this.campaignId);
  final String campaignId;
}

class LoadCampaignImpressionsEvent extends CampaignDetailEvent {
  LoadCampaignImpressionsEvent({this.page = 1});
  final int page;
}

class UpdateCampaignDetailStatusEvent extends CampaignDetailEvent {
  UpdateCampaignDetailStatusEvent(this.status);
  final String status;
}

class UpdateCampaignTargetingEvent extends CampaignDetailEvent {
  UpdateCampaignTargetingEvent(this.data);
  final UpdateCampaignData data;
}

class DeleteCampaignDetailEvent extends CampaignDetailEvent {}

abstract class CampaignDetailState {}

class CampaignDetailInitial extends CampaignDetailState {}

class CampaignDetailLoading extends CampaignDetailState {}

class CampaignDetailLoaded extends CampaignDetailState {
  CampaignDetailLoaded({
    required this.campaign,
    required this.stats,
    required this.impressions,
    required this.impressionsMeta,
    this.isActioning = false,
    this.message,
    this.isError = false,
  });

  final CampaignEntity campaign;
  final CampaignStatsEntity stats;
  final List<CampaignImpressionEntity> impressions;
  final PaginationMeta impressionsMeta;
  final bool isActioning;
  final String? message;
  final bool isError;

  CampaignDetailLoaded copyWith({
    CampaignEntity? campaign,
    CampaignStatsEntity? stats,
    List<CampaignImpressionEntity>? impressions,
    PaginationMeta? impressionsMeta,
    bool? isActioning,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return CampaignDetailLoaded(
      campaign: campaign ?? this.campaign,
      stats: stats ?? this.stats,
      impressions: impressions ?? this.impressions,
      impressionsMeta: impressionsMeta ?? this.impressionsMeta,
      isActioning: isActioning ?? this.isActioning,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }
}

class CampaignDetailError extends CampaignDetailState {
  CampaignDetailError(this.message);
  final String message;
}

class CampaignDetailBloc
    extends Bloc<CampaignDetailEvent, CampaignDetailState> {
  CampaignDetailBloc({
    required GetCampaignDetailUseCase getDetail,
    required GetCampaignStatsUseCase getStats,
    required GetCampaignImpressionsUseCase getImpressions,
    required UpdateCampaignUseCase updateCampaign,
    required UpdateCampaignStatusUseCase updateStatus,
    required DeleteCampaignUseCase deleteCampaign,
  })  : _getDetail = getDetail,
        _getStats = getStats,
        _getImpressions = getImpressions,
        _updateCampaign = updateCampaign,
        _updateStatus = updateStatus,
        _deleteCampaign = deleteCampaign,
        super(CampaignDetailInitial()) {
    on<LoadCampaignDetailEvent>(_onLoad);
    on<LoadCampaignImpressionsEvent>(_onLoadImpressions);
    on<UpdateCampaignDetailStatusEvent>(_onUpdateStatus);
    on<UpdateCampaignTargetingEvent>(_onUpdateTargeting);
    on<DeleteCampaignDetailEvent>(_onDelete);
  }

  final GetCampaignDetailUseCase _getDetail;
  final GetCampaignStatsUseCase _getStats;
  final GetCampaignImpressionsUseCase _getImpressions;
  final UpdateCampaignUseCase _updateCampaign;
  final UpdateCampaignStatusUseCase _updateStatus;
  final DeleteCampaignUseCase _deleteCampaign;
  String? _campaignId;

  Future<void> _onLoad(
    LoadCampaignDetailEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    _campaignId = event.campaignId;
    emit(CampaignDetailLoading());
    try {
      final campaign = await _getDetail(event.campaignId);
      final stats = await _getStats(event.campaignId);
      final impressions = await _getImpressions(
        campaignId: event.campaignId,
        page: 1,
        limit: 50,
      );
      emit(
        CampaignDetailLoaded(
          campaign: campaign,
          stats: stats,
          impressions: impressions.data,
          impressionsMeta: impressions.meta,
        ),
      );
    } catch (e) {
      emit(CampaignDetailError(e.toString()));
    }
  }

  Future<void> _onLoadImpressions(
    LoadCampaignImpressionsEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    final current = state;
    final id = _campaignId;
    if (current is! CampaignDetailLoaded || id == null) return;
    try {
      final impressions = await _getImpressions(
        campaignId: id,
        page: event.page,
        limit: 50,
      );
      emit(
        current.copyWith(
          impressions: impressions.data,
          impressionsMeta: impressions.meta,
        ),
      );
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isError: true));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateCampaignDetailStatusEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    final current = state;
    final id = _campaignId;
    if (current is! CampaignDetailLoaded || id == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      final campaign = await _updateStatus(id, event.status);
      final stats = await _getStats(id);
      emit(current.copyWith(
        campaign: campaign,
        stats: stats,
        isActioning: false,
      ));
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onUpdateTargeting(
    UpdateCampaignTargetingEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    final current = state;
    final id = _campaignId;
    if (current is! CampaignDetailLoaded || id == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      final campaign = await _updateCampaign(id, event.data);
      final stats = await _getStats(id);
      emit(current.copyWith(
        campaign: campaign,
        stats: stats,
        isActioning: false,
      ));
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onDelete(
    DeleteCampaignDetailEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    final current = state;
    final id = _campaignId;
    if (current is! CampaignDetailLoaded || id == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _deleteCampaign(id);
      emit(CampaignDetailError('deleted'));
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }
}
