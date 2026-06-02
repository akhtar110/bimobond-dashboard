import '../../domain/entities/auction_entity.dart';
import '../../domain/repositories/auctions_repository.dart';
import '../datasources/auctions_remote_datasource.dart';

class AuctionsRepositoryImpl implements AuctionsRepository {
  const AuctionsRepositoryImpl(this._dataSource);
  final AuctionsRemoteDataSource _dataSource;

  @override
  Future<List<AuctionEntity>> getAllAuctions() =>
      _dataSource.getAllAuctions();

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
