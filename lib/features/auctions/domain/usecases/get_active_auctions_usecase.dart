import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class GetActiveAuctions {
  const GetActiveAuctions(this.repository);
  final AuctionsRepository repository;

  Future<List<AuctionEntity>> call() => repository.getActiveAuctions();
}
