import '../entities/auction_pricing_preview_entity.dart';
import '../repositories/auctions_repository.dart';

class PreviewAuctionPricing {
  const PreviewAuctionPricing(this.repository);
  final AuctionsRepository repository;

  Future<AuctionPricingPreviewEntity> call({
    double? targetPrice,
    double? targetPriceCoins,
    String? currencyCode,
  }) =>
      repository.previewAuctionPricing(
        targetPrice: targetPrice,
        targetPriceCoins: targetPriceCoins,
        currencyCode: currencyCode,
      );
}
