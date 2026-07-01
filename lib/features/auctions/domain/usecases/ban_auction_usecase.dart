import '../repositories/auctions_repository.dart';

class AdminBanAuction {
  const AdminBanAuction(this.repository);
  final AuctionsRepository repository;
  Future<void> call(String auctionId) => repository.adminBanAuction(auctionId);
}
