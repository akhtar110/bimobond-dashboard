import '../../domain/entities/auction_pricing_preview_entity.dart';

class AuctionPricingPreviewModel extends AuctionPricingPreviewEntity {
  const AuctionPricingPreviewModel({
    super.inputTargetPrice,
    super.inputTargetPriceCoins,
    super.inputCurrencyCode,
    super.resolvedTargetPrice,
    super.resolvedTargetPriceCoins,
    super.resolvedCurrencyCode,
    super.estimatedBidderSpendCoins,
    super.estimatedBidderSpendPrice,
    super.progressPercent,
  });

  factory AuctionPricingPreviewModel.fromJson(Map<String, dynamic> json) {
    final input = json['input'];
    final resolved = json['resolved'];
    final pricing = json['pricing'];

    Map<String, dynamic>? inputMap;
    Map<String, dynamic>? resolvedMap;
    Map<String, dynamic>? pricingMap;

    if (input is Map<String, dynamic>) inputMap = input;
    if (resolved is Map<String, dynamic>) resolvedMap = resolved;
    if (pricing is Map<String, dynamic>) pricingMap = pricing;

    return AuctionPricingPreviewModel(
      inputTargetPrice: _optionalD(inputMap?['targetPrice']),
      inputTargetPriceCoins: _optionalD(inputMap?['targetPriceCoins']),
      inputCurrencyCode: inputMap?['currencyCode']?.toString(),
      resolvedTargetPrice: _optionalD(resolvedMap?['targetPrice']),
      resolvedTargetPriceCoins: _optionalD(resolvedMap?['targetPriceCoins']),
      resolvedCurrencyCode: resolvedMap?['currencyCode']?.toString(),
      estimatedBidderSpendCoins:
          _optionalD(pricingMap?['estimatedBidderSpendCoins']),
      estimatedBidderSpendPrice:
          _optionalD(pricingMap?['estimatedBidderSpendPrice']),
      progressPercent: _optionalD(pricingMap?['progressPercent']),
    );
  }

  static double? _optionalD(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
