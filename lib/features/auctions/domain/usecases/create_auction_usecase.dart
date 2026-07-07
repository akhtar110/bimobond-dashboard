import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class CreateAuction {
  const CreateAuction(this.repository);
  final AuctionsRepository repository;

  Future<AuctionEntity> call(Map<String, dynamic> body) =>
      repository.createAuction(body);
}
