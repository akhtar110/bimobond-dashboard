/// Response from `GET /auctions/pricing/preview`.
class AuctionPricingPreviewEntity {
  const AuctionPricingPreviewEntity({
    this.inputTargetPrice,
    this.inputTargetPriceCoins,
    this.inputCurrencyCode,
    this.resolvedTargetPrice,
    this.resolvedTargetPriceCoins,
    this.resolvedCurrencyCode,
    this.estimatedBidderSpendCoins,
    this.estimatedBidderSpendPrice,
    this.progressPercent,
  });

  final double? inputTargetPrice;
  final double? inputTargetPriceCoins;
  final String? inputCurrencyCode;
  final double? resolvedTargetPrice;
  final double? resolvedTargetPriceCoins;
  final String? resolvedCurrencyCode;
  final double? estimatedBidderSpendCoins;
  final double? estimatedBidderSpendPrice;
  final double? progressPercent;
}
