import '../entities/auction_entity.dart';

abstract class AuctionsRepository {
  Future<List<AuctionEntity>> getAllAuctions();
  Future<AuctionEntity> getAuctionDetails(String auctionId);
  Future<void> adminCancelAuction(String auctionId);
  Future<AuctionEntity> adminResolveAuction(String auctionId, String winnerId);
}
