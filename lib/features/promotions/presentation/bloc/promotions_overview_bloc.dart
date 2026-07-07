import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promotion_entities.dart';
import '../../domain/entities/promotion_overview_entity.dart';
import '../../domain/usecases/promotion_usecases.dart';

abstract class PromotionsOverviewEvent {}

class LoadPromotionsOverviewEvent extends PromotionsOverviewEvent {}

class PromotionsOverviewState {}

class PromotionsOverviewInitial extends PromotionsOverviewState {}

class PromotionsOverviewLoading extends PromotionsOverviewState {}

class PromotionsOverviewLoaded extends PromotionsOverviewState {
  PromotionsOverviewLoaded({
    required this.overview,
    required this.recentCampaigns,
    required this.moderationQueue,
  });

  final PromotionOverviewEntity overview;
  final List<CampaignEntity> recentCampaigns;
  final List<CampaignEntity> moderationQueue;
}

class PromotionsOverviewError extends PromotionsOverviewState {
  PromotionsOverviewError(this.message);
  final String message;
}

class PromotionsOverviewBloc
    extends Bloc<PromotionsOverviewEvent, PromotionsOverviewState> {
  PromotionsOverviewBloc({
    required GetPromotionsOverviewUseCase getOverview,
    required GetCampaignsUseCase getCampaigns,
  })  : _getOverview = getOverview,
        _getCampaigns = getCampaigns,
        super(PromotionsOverviewInitial()) {
    on<LoadPromotionsOverviewEvent>(_onLoad);
  }

  final GetPromotionsOverviewUseCase _getOverview;
  final GetCampaignsUseCase _getCampaigns;

  Future<void> _onLoad(
    LoadPromotionsOverviewEvent event,
    Emitter<PromotionsOverviewState> emit,
  ) async {
    emit(PromotionsOverviewLoading());
    try {
      final overview = await _getOverview();
      final recent = await _getCampaigns(
        const AdminCampaignsQuery(page: 1, limit: 5),
      );
      final moderation = await _getCampaigns(
        const AdminCampaignsQuery(
          page: 1,
          limit: 5,
          status: 'PENDING_PAYMENT',
        ),
      );
      emit(
        PromotionsOverviewLoaded(
          overview: overview,
          recentCampaigns: recent.data,
          moderationQueue: moderation.data,
        ),
      );
    } catch (e) {
      emit(PromotionsOverviewError(e.toString()));
    }
  }
}
