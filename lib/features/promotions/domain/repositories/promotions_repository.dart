import '../entities/pagination_meta.dart';
import '../entities/promoted_post_entities.dart';
import '../entities/promotion_entities.dart';
import '../entities/promotion_overview_entity.dart';

abstract class PromotionsRepository {
  Future<PromotionOverviewEntity> getOverview();

  Future<PaginatedResult<CampaignEntity>> getCampaigns(AdminCampaignsQuery query);

  Future<CampaignEntity> getCampaignDetail(String campaignId);

  Future<CampaignStatsEntity> getCampaignStats(String campaignId);

  Future<PaginatedResult<CampaignImpressionEntity>> getCampaignImpressions({
    required String campaignId,
    int page = 1,
    int limit = 50,
    String? viewerId,
  });

  Future<CampaignEntity> updateCampaign(
    String campaignId,
    UpdateCampaignData data,
  );

  Future<CampaignEntity> updateCampaignStatus(
    String campaignId,
    String status,
  );

  Future<void> deleteCampaign(String campaignId);

  Future<BulkActionResultEntity> bulkAction(BulkCampaignActionRequest request);

  Future<List<PromotionPackageEntity>> getPackages({PackagesQuery query = const PackagesQuery()});

  Future<PromotionPackageEntity> createPackage(CreatePackageData data);

  Future<PromotionPackageEntity> updatePackage(
    String packageId,
    UpdatePackageData data,
  );

  Future<PromotionPackageEntity> activatePackage(String packageId);

  Future<PromotionPackageEntity> deactivatePackage(String packageId);

  Future<void> deletePackage(String packageId);

  Future<PromotedPostsPageEntity> getPromotedPosts(PromotedPostsQuery query);

  Future<PromotedPostDetailEntity> getPromotedPostDetail(String postId);

  Future<PostPromotionStatsEntity> getPromotedPostStats(
    String postId, {
    String? campaignId,
  });

  Future<PostPromotionStatsEntity> getAdminPromotedPostStats(
    String postId, {
    String? campaignId,
  });
}

abstract class LocationIntelligenceRepository {
  Future<PaginatedResult<LocationPointEntity>> getLocationHistory({
    required String userId,
    required LocationHistoryQuery query,
  });

  Future<MovementPathEntity> getMovementPath({
    required String userId,
    required MovementPathQuery query,
  });
}
