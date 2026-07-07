import '../entities/admin_auctions_query.dart';
import '../entities/auctions_page_entity.dart';
import '../repositories/auctions_repository.dart';

class GetAllAuctions {
  const GetAllAuctions(this.repository);
  final AuctionsRepository repository;

  Future<AuctionsPageEntity> call({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  }) =>
      repository.getAdminAuctions(page: page, limit: limit, query: query);
}
