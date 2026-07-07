import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class AdminBanAuction {
  const AdminBanAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(String auctionId) =>
      repository.adminBanAuction(auctionId);
}
