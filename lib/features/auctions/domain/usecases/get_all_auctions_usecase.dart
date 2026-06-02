import '../entities/auction_entity.dart';
import '../repositories/auctions_repository.dart';

class GetAllAuctions {
  const GetAllAuctions(this.repository);
  final AuctionsRepository repository;
  Future<List<AuctionEntity>> call() => repository.getAllAuctions();
}
