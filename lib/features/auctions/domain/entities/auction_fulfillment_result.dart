import 'auction_entity.dart';

class AuctionFulfillmentActionResult {
  const AuctionFulfillmentActionResult({
    required this.auction,
    this.refundedCount,
    this.alreadySettled = false,
  });

  final AuctionEntity auction;
  final int? refundedCount;
  final bool alreadySettled;
}
