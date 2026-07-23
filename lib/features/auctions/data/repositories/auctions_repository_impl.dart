import '../../domain/entities/auction_fulfillment_result.dart';
import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_pricing_preview_entity.dart';
import '../../domain/entities/auction_update_body.dart';
import '../../domain/entities/auctions_page_entity.dart';
import '../../domain/repositories/auctions_repository.dart';
import '../datasources/auctions_remote_datasource.dart';

class AuctionsRepositoryImpl implements AuctionsRepository {
  const AuctionsRepositoryImpl(this._dataSource);
  final AuctionsRemoteDataSource _dataSource;

  @override
  Future<List<AuctionEntity>> getActiveAuctions() =>
      _dataSource.getActiveAuctions();

  @override
  Future<AuctionsPageEntity> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  }) =>
      _dataSource.getAdminAuctions(page: page, limit: limit, query: query);

  @override
  Future<AuctionEntity> getAuctionDetails(String auctionId) =>
      _dataSource.getAuctionDetails(auctionId);

  @override
  Future<AuctionPricingPreviewEntity> previewAuctionPricing({
    double? targetPrice,
    double? targetPriceCoins,
    String? currencyCode,
  }) =>
      _dataSource.previewAuctionPricing(
        targetPrice: targetPrice,
        targetPriceCoins: targetPriceCoins,
        currencyCode: currencyCode,
      );

  @override
  Future<AuctionEntity> createAuction(Map<String, dynamic> body) =>
      _dataSource.createAuction(body);

  @override
  Future<AuctionEntity> hostUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  ) =>
      _dataSource.hostUpdateAuction(auctionId, body);

  @override
  Future<AuctionEntity> hostCancelAuction(String auctionId) =>
      _dataSource.hostCancelAuction(auctionId);

  @override
  Future<AuctionEntity> adminCancelAuction(String auctionId) =>
      _dataSource.adminCancelAuction(auctionId);

  @override
  Future<AuctionEntity> adminBanAuction(String auctionId) =>
      _dataSource.adminBanAuction(auctionId);

  @override
  Future<AuctionEntity> adminUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  ) =>
      _dataSource.adminUpdateAuction(auctionId, body);

  @override
  Future<AuctionEntity> adminResolveAuction(
    String auctionId,
    String winnerId,
  ) =>
      _dataSource.adminResolveAuction(auctionId, winnerId);

  @override
  Future<AuctionFulfillmentActionResult> adminRefundFulfillment(
    String auctionId,
  ) =>
      _dataSource.adminRefundFulfillment(auctionId);

  @override
  Future<AuctionFulfillmentActionResult> adminReleaseFulfillment(
    String auctionId,
  ) =>
      _dataSource.adminReleaseFulfillment(auctionId);
}
