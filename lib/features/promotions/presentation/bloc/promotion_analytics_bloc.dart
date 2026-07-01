import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/usecases/promotion_usecases.dart';

abstract class PromotionAnalyticsEvent extends Equatable {
  const PromotionAnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPromotionAnalyticsEvent extends PromotionAnalyticsEvent {
  const LoadPromotionAnalyticsEvent({
    required this.postId,
    this.campaignId,
    this.refresh = false,
  });

  final String postId;
  final String? campaignId;
  final bool refresh;

  @override
  List<Object?> get props => [postId, campaignId, refresh];
}

class FilterPromotionAnalyticsCampaignEvent extends PromotionAnalyticsEvent {
  const FilterPromotionAnalyticsCampaignEvent(this.campaignId);
  final String? campaignId;
  @override
  List<Object?> get props => [campaignId];
}

class UpdateCampaignStatusFromAnalyticsEvent extends PromotionAnalyticsEvent {
  const UpdateCampaignStatusFromAnalyticsEvent(this.campaignId, this.status);
  final String campaignId;
  final String status;
  @override
  List<Object?> get props => [campaignId, status];
}

abstract class PromotionAnalyticsState extends Equatable {
  const PromotionAnalyticsState();
  @override
  List<Object?> get props => [];
}

class PromotionAnalyticsInitial extends PromotionAnalyticsState {}

class PromotionAnalyticsLoading extends PromotionAnalyticsState {}

class PromotionAnalyticsLoaded extends PromotionAnalyticsState {
  const PromotionAnalyticsLoaded({
    required this.stats,
    required this.postId,
    this.selectedCampaignId,
    this.isActioning = false,
    this.message,
    this.isError = false,
  });

  final PostPromotionStatsEntity stats;
  final String postId;
  final String? selectedCampaignId;
  final bool isActioning;
  final String? message;
  final bool isError;

  PromotionAnalyticsLoaded copyWith({
    PostPromotionStatsEntity? stats,
    String? postId,
    String? selectedCampaignId,
    bool clearCampaignFilter = false,
    bool? isActioning,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return PromotionAnalyticsLoaded(
      stats: stats ?? this.stats,
      postId: postId ?? this.postId,
      selectedCampaignId:
          clearCampaignFilter ? null : (selectedCampaignId ?? this.selectedCampaignId),
      isActioning: isActioning ?? this.isActioning,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props =>
      [stats, postId, selectedCampaignId, isActioning, message, isError];
}

class PromotionAnalyticsEmpty extends PromotionAnalyticsState {}

class PromotionAnalyticsError extends PromotionAnalyticsState {
  const PromotionAnalyticsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class PromotionAnalyticsBloc
    extends Bloc<PromotionAnalyticsEvent, PromotionAnalyticsState> {
  PromotionAnalyticsBloc({
    required GetAdminPromotedPostStatsUseCase getAdminStats,
    required UpdateCampaignStatusUseCase updateStatus,
    required GetSingleCampaignStatsUseCase getCampaignStats,
  })  : _getAdminStats = getAdminStats,
        _updateStatus = updateStatus,
        _getCampaignStats = getCampaignStats,
        super(PromotionAnalyticsInitial()) {
    on<LoadPromotionAnalyticsEvent>(_onLoad);
    on<FilterPromotionAnalyticsCampaignEvent>(_onFilterCampaign);
    on<UpdateCampaignStatusFromAnalyticsEvent>(_onUpdateStatus);
  }

  final GetAdminPromotedPostStatsUseCase _getAdminStats;
  final UpdateCampaignStatusUseCase _updateStatus;
  final GetSingleCampaignStatsUseCase _getCampaignStats;

  final Map<String, PostPromotionStatsEntity> _statsCache = {};

  Future<void> _onLoad(
    LoadPromotionAnalyticsEvent event,
    Emitter<PromotionAnalyticsState> emit,
  ) async {
    final cacheKey = '${event.postId}:${event.campaignId ?? 'all'}';
    final cached = _statsCache[cacheKey];
    final current = state;

    if (cached != null && !event.refresh) {
      emit(
        PromotionAnalyticsLoaded(
          stats: cached,
          postId: event.postId,
          selectedCampaignId: event.campaignId,
        ),
      );
      return;
    }

    if (current is! PromotionAnalyticsLoaded) {
      emit(PromotionAnalyticsLoading());
    } else {
      emit(current.copyWith(isActioning: true, clearMessage: true));
    }

    try {
      final stats = await _getAdminStats(
        event.postId,
        campaignId: event.campaignId,
      );
      _statsCache[cacheKey] = stats;
      if (stats.campaigns.isEmpty && stats.statistics.views == 0) {
        emit(PromotionAnalyticsEmpty());
      } else {
        emit(
          PromotionAnalyticsLoaded(
            stats: stats,
            postId: event.postId,
            selectedCampaignId: event.campaignId,
          ),
        );
      }
    } catch (e) {
      if (current is PromotionAnalyticsLoaded) {
        emit(current.copyWith(
          isActioning: false,
          message: e.toString(),
          isError: true,
        ));
      } else {
        emit(PromotionAnalyticsError(e.toString()));
      }
    }
  }

  void _onFilterCampaign(
    FilterPromotionAnalyticsCampaignEvent event,
    Emitter<PromotionAnalyticsState> emit,
  ) {
    final current = state;
    if (current is! PromotionAnalyticsLoaded) return;
    add(
      LoadPromotionAnalyticsEvent(
        postId: current.postId,
        campaignId: event.campaignId,
        refresh: true,
      ),
    );
  }

  Future<void> _onUpdateStatus(
    UpdateCampaignStatusFromAnalyticsEvent event,
    Emitter<PromotionAnalyticsState> emit,
  ) async {
    final current = state;
    if (current is! PromotionAnalyticsLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _updateStatus(event.campaignId, event.status);
      await _getCampaignStats(event.campaignId);
      _statsCache.removeWhere((key, _) => key.startsWith('${current.postId}:'));
      add(
        LoadPromotionAnalyticsEvent(
          postId: current.postId,
          campaignId: current.selectedCampaignId,
          refresh: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }
}
