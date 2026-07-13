import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/entities/promotion_overview_entity.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../datasources/promotions_remote_datasource.dart';

class PromotionsRepositoryImpl implements PromotionsRepository {
  const PromotionsRepositoryImpl(this._remote);
  final PromotionsRemoteDataSource _remote;

  @override
  Future<PromotionOverviewEntity> getOverview() => _remote.getOverview();

  @override
  Future<PaginatedResult<CampaignEntity>> getCampaigns(
    AdminCampaignsQuery query,
  ) =>
      _remote.getCampaigns(query);

  @override
  Future<CampaignEntity> getCampaignDetail(String campaignId) =>
      _remote.getCampaignDetail(campaignId);

  @override
  Future<CampaignStatsEntity> getCampaignStats(String campaignId) =>
      _remote.getCampaignStats(campaignId);

  @override
  Future<PaginatedResult<CampaignImpressionEntity>> getCampaignImpressions({
    required String campaignId,
    int page = 1,
    int limit = 50,
    String? viewerId,
  }) =>
      _remote.getCampaignImpressions(
        campaignId: campaignId,
        page: page,
        limit: limit,
        viewerId: viewerId,
      );

  @override
  Future<CampaignEntity> updateCampaign(
    String campaignId,
    UpdateCampaignData data,
  ) =>
      _remote.updateCampaign(campaignId, data);

  @override
  Future<CampaignEntity> updateCampaignStatus(
    String campaignId,
    String status,
  ) =>
      _remote.updateCampaignStatus(campaignId, status);

  @override
  Future<void> deleteCampaign(String campaignId) =>
      _remote.deleteCampaign(campaignId);

  @override
  Future<BulkActionResultEntity> bulkAction(
    BulkCampaignActionRequest request,
  ) =>
      _remote.bulkAction(request);

  @override
  Future<List<PromotionPackageEntity>> getPackages({PackagesQuery query = const PackagesQuery()}) =>
      _remote.getPackages(query: query);

  @override
  Future<PromotionPackageEntity> createPackage(CreatePackageData data) =>
      _remote.createPackage(data);

  @override
  Future<PromotionPackageEntity> updatePackage(
    String packageId,
    UpdatePackageData data,
  ) =>
      _remote.updatePackage(packageId, data);

  @override
  Future<PromotionPackageEntity> activatePackage(String packageId) =>
      _remote.activatePackage(packageId);

  @override
  Future<PromotionPackageEntity> deactivatePackage(String packageId) =>
      _remote.deactivatePackage(packageId);

  @override
  Future<void> deletePackage(String packageId) =>
      _remote.deletePackage(packageId);

  @override
  Future<PromotedPostsPageEntity> getPromotedPosts(PromotedPostsQuery query) =>
      _remote.getPromotedPosts(query);

  @override
  Future<PromotedPostDetailEntity> getPromotedPostDetail(String postId) =>
      _remote.getPromotedPostDetail(postId);

  @override
  Future<PostPromotionStatsEntity> getPromotedPostStats(
    String postId, {
    String? campaignId,
  }) =>
      _remote.getPromotedPostStats(postId, campaignId: campaignId);

  @override
  Future<PostPromotionStatsEntity> getAdminPromotedPostStats(
    String postId, {
    String? campaignId,
  }) =>
      _remote.getAdminPromotedPostStats(postId, campaignId: campaignId);
}

class LocationIntelligenceRepositoryImpl
    implements LocationIntelligenceRepository {
  const LocationIntelligenceRepositoryImpl(this._remote);
  final LocationIntelligenceRemoteDataSource _remote;

  @override
  Future<PaginatedResult<LocationPointEntity>> getLocationHistory({
    required String userId,
    required LocationHistoryQuery query,
  }) =>
      _remote.getLocationHistory(userId: userId, query: query);

  @override
  Future<MovementPathEntity> getMovementPath({
    required String userId,
    required MovementPathQuery query,
  }) =>
      _remote.getMovementPath(userId: userId, query: query);
}
