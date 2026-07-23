import '../entities/auction_fulfillment_result.dart';
import '../repositories/auctions_repository.dart';

class AdminRefundFulfillment {
  const AdminRefundFulfillment(this.repository);
  final AuctionsRepository repository;

  Future<AuctionFulfillmentActionResult> call(String auctionId) =>
      repository.adminRefundFulfillment(auctionId);
}
