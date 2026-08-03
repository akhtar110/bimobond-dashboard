import '../entities/admin_auctions_query.dart';
import '../entities/auction_entity.dart';
import '../entities/auction_fulfillment_result.dart';
import '../entities/auction_pricing_preview_entity.dart';
import '../entities/auction_update_body.dart';
import '../entities/auctions_page_entity.dart';

abstract class AuctionsRepository {
  Future<List<AuctionEntity>> getActiveAuctions();

  Future<AuctionsPageEntity> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  });

  Future<AuctionEntity> getAuctionDetails(String auctionId);

  Future<AuctionPricingPreviewEntity> previewAuctionPricing({
    double? targetPrice,
    double? targetPriceCoins,
    String? currencyCode,
  });

  Future<AuctionEntity> createAuction(Map<String, dynamic> body);

  Future<AuctionEntity> hostUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  );

  Future<AuctionEntity> hostCancelAuction(String auctionId);

  Future<AuctionEntity> adminCancelAuction(String auctionId);

  Future<AuctionEntity> adminBanAuction(String auctionId);

  /// Restores a BANNED auction — `PATCH /auctions/admin/:id/unban`.
  Future<AuctionEntity> adminUnbanAuction(String auctionId);

  Future<AuctionEntity> adminUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  );

  Future<AuctionEntity> adminResolveAuction(String auctionId, String winnerId);

  Future<AuctionFulfillmentActionResult> adminRefundFulfillment(String auctionId);

  Future<AuctionFulfillmentActionResult> adminReleaseFulfillment(String auctionId);
}
