import '../entities/auction_entity.dart';
import '../entities/auction_update_body.dart';
import '../repositories/auctions_repository.dart';

class AdminUpdateAuction {
  const AdminUpdateAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(String auctionId, AuctionUpdateBody body) =>
      repository.adminUpdateAuction(auctionId, body);
}
