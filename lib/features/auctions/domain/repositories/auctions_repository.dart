import '../entities/admin_auctions_query.dart';
import '../entities/auction_entity.dart';
import '../entities/auctions_page_entity.dart';

abstract class AuctionsRepository {
  Future<AuctionsPageEntity> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  });
  Future<AuctionEntity> getAuctionDetails(String auctionId);
  Future<void> adminCancelAuction(String auctionId);
  Future<AuctionEntity> adminResolveAuction(String auctionId, String winnerId);
}
