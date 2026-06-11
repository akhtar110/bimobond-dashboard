import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auctions_page_entity.dart';
import '../../domain/repositories/auctions_repository.dart';
import '../datasources/auctions_remote_datasource.dart';

class AuctionsRepositoryImpl implements AuctionsRepository {
  const AuctionsRepositoryImpl(this._dataSource);
  final AuctionsRemoteDataSource _dataSource;

  @override
  Future<AuctionsPageEntity> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  }) =>
      _dataSource.getAdminAuctions(page: page, limit: limit, query: query);

  @override
  Future<AuctionEntity> getAuctionDetails(String auctionId) =>
      _dataSource.getAuctionDetails(auctionId);

  @override
  Future<void> adminCancelAuction(String auctionId) =>
      _dataSource.adminCancelAuction(auctionId);

  @override
  Future<AuctionEntity> adminResolveAuction(
          String auctionId, String winnerId) =>
      _dataSource.adminResolveAuction(auctionId, winnerId);
}
