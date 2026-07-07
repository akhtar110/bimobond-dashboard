import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class AdminCancelAuction {
  const AdminCancelAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(String auctionId) =>
      repository.adminCancelAuction(auctionId);
}
