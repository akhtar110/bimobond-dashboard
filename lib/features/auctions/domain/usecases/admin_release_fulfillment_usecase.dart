import '../entities/auction_fulfillment_result.dart';
import '../repositories/auctions_repository.dart';

class AdminReleaseFulfillment {
  const AdminReleaseFulfillment(this.repository);
  final AuctionsRepository repository;

  Future<AuctionFulfillmentActionResult> call(String auctionId) =>
      repository.adminReleaseFulfillment(auctionId);
}
