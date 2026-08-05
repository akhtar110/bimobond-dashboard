import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

/// Admin unban — `PATCH /auctions/admin/:id/unban`.
class AdminUnbanAuction {
  const AdminUnbanAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(String auctionId) =>
      repository.adminUnbanAuction(auctionId);
}
