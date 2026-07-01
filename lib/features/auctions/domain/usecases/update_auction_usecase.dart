import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class AdminUpdateAuction {
  const AdminUpdateAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(
    String auctionId, {
    String? itemName,
    String? status,
  }) =>
      repository.adminUpdateAuction(
        auctionId,
        itemName: itemName,
        status: status,
      );
}
