import '../repositories/auctions_repository.dart';

class AdminCancelAuction {
  const AdminCancelAuction(this.repository);
  final AuctionsRepository repository;
  Future<void> call(String auctionId) =>
      repository.adminCancelAuction(auctionId);
}
