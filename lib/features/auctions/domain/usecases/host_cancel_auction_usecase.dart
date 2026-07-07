import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class HostCancelAuction {
  const HostCancelAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(String auctionId) =>
      repository.hostCancelAuction(auctionId);
}
