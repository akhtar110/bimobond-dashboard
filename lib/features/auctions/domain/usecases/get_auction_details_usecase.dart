import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class GetAuctionDetails {
  const GetAuctionDetails(this.repository);
  final AuctionsRepository repository;
  Future<AuctionEntity> call(String auctionId) =>
      repository.getAuctionDetails(auctionId);
}
