import '../entities/pagination_meta.dart';
import '../entities/promoted_post_entities.dart';
import '../entities/promotion_entities.dart';
import '../entities/promotion_overview_entity.dart';
import '../repositories/promotions_repository.dart';

class GetPromotionsOverviewUseCase {
  const GetPromotionsOverviewUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotionOverviewEntity> call() => _repository.getOverview();
}

class GetCampaignsUseCase {
  const GetCampaignsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PaginatedResult<CampaignEntity>> call(AdminCampaignsQuery query) =>
      _repository.getCampaigns(query);
}

class GetCampaignDetailUseCase {
  const GetCampaignDetailUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<CampaignEntity> call(String campaignId) =>
      _repository.getCampaignDetail(campaignId);
}

class GetCampaignStatsUseCase {
  const GetCampaignStatsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<CampaignStatsEntity> call(String campaignId) =>
      _repository.getCampaignStats(campaignId);
}

class GetCampaignImpressionsUseCase {
  const GetCampaignImpressionsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PaginatedResult<CampaignImpressionEntity>> call({
    required String campaignId,
    int page = 1,
    int limit = 50,
    String? viewerId,
  }) =>
      _repository.getCampaignImpressions(
        campaignId: campaignId,
        page: page,
        limit: limit,
        viewerId: viewerId,
      );
}

class UpdateCampaignUseCase {
  const UpdateCampaignUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<CampaignEntity> call(String campaignId, UpdateCampaignData data) =>
      _repository.updateCampaign(campaignId, data);
}

class UpdateCampaignStatusUseCase {
  const UpdateCampaignStatusUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<CampaignEntity> call(String campaignId, String status) =>
      _repository.updateCampaignStatus(campaignId, status);
}

class DeleteCampaignUseCase {
  const DeleteCampaignUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<void> call(String campaignId) => _repository.deleteCampaign(campaignId);
}

class BulkCampaignActionUseCase {
  const BulkCampaignActionUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<BulkActionResultEntity> call(BulkCampaignActionRequest request) =>
      _repository.bulkAction(request);
}

class GetPackagesUseCase {
  const GetPackagesUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<List<PromotionPackageEntity>> call({PackagesQuery query = const PackagesQuery()}) =>
      _repository.getPackages(query: query);
}

class CreatePackageUseCase {
  const CreatePackageUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotionPackageEntity> call(CreatePackageData data) =>
      _repository.createPackage(data);
}

class UpdatePackageUseCase {
  const UpdatePackageUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotionPackageEntity> call(
    String packageId,
    UpdatePackageData data,
  ) =>
      _repository.updatePackage(packageId, data);
}

class TogglePackageStatusUseCase {
  const TogglePackageStatusUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotionPackageEntity> activate(String packageId) =>
      _repository.activatePackage(packageId);
  Future<PromotionPackageEntity> deactivate(String packageId) =>
      _repository.deactivatePackage(packageId);
}

class DeletePackageUseCase {
  const DeletePackageUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<void> call(String packageId) => _repository.deletePackage(packageId);
}

class GetLocationHistoryUseCase {
  const GetLocationHistoryUseCase(this._repository);
  final LocationIntelligenceRepository _repository;
  Future<PaginatedResult<LocationPointEntity>> call({
    required String userId,
    required LocationHistoryQuery query,
  }) =>
      _repository.getLocationHistory(userId: userId, query: query);
}

class GetMovementPathUseCase {
  const GetMovementPathUseCase(this._repository);
  final LocationIntelligenceRepository _repository;
  Future<MovementPathEntity> call({
    required String userId,
    required MovementPathQuery query,
  }) =>
      _repository.getMovementPath(userId: userId, query: query);
}

class GetPromotedPostsUseCase {
  const GetPromotedPostsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotedPostsPageEntity> call(PromotedPostsQuery query) =>
      _repository.getPromotedPosts(query);
}

class GetPromotedPostDetailUseCase {
  const GetPromotedPostDetailUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PromotedPostDetailEntity> call(String postId) =>
      _repository.getPromotedPostDetail(postId);
}

class GetPromotedPostStatsUseCase {
  const GetPromotedPostStatsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PostPromotionStatsEntity> call(
    String postId, {
    String? campaignId,
  }) =>
      _repository.getPromotedPostStats(postId, campaignId: campaignId);
}

class GetAdminPromotedPostStatsUseCase {
  const GetAdminPromotedPostStatsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<PostPromotionStatsEntity> call(
    String postId, {
    String? campaignId,
  }) =>
      _repository.getAdminPromotedPostStats(postId, campaignId: campaignId);
}

class GetSingleCampaignStatsUseCase {
  const GetSingleCampaignStatsUseCase(this._repository);
  final PromotionsRepository _repository;
  Future<CampaignStatsEntity> call(String campaignId) =>
      _repository.getCampaignStats(campaignId);
}
