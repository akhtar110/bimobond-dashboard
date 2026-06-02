import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class AdminResolveAuction {
  const AdminResolveAuction(this.repository);
  final AuctionsRepository repository;
  Future<AuctionEntity> call(String auctionId, String winnerId) =>
      repository.adminResolveAuction(auctionId, winnerId);
}
