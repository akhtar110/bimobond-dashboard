import 'auction_entity.dart';

class AuctionUpdateEntity {
  const AuctionUpdateEntity({
    required this.auctionId,
    required this.currentTotalCoins,
    required this.targetPriceCoins,
    required this.status,
    this.winnerId,
    this.lastGift,
    this.pricing,
  });

  final String auctionId;
  final double currentTotalCoins;
  final double targetPriceCoins;
  final String status;
  final String? winnerId;
  final Map<String, dynamic>? lastGift;
  final AuctionPricingEntity? pricing;

  String? get lastGiftName => lastGift?['name'] as String?;
  String? get lastGiftThumbnail => lastGift?['thumbnailUrl'] as String?;

  factory AuctionUpdateEntity.fromJson(Map<String, dynamic> json) {
    final pricingJson = json['pricing'];
    return AuctionUpdateEntity(
      auctionId: json['auctionId']?.toString() ?? '',
      currentTotalCoins: _toDouble(
        json['currentTotalCoins'] ?? json['currentTotalUsd'],
      ),
      targetPriceCoins: _toDouble(
        json['targetPriceCoins'] ?? json['targetPriceUsd'],
      ),
      status: json['status']?.toString() ?? 'ACTIVE',
      winnerId: json['winnerId'] as String?,
      lastGift: json['lastGift'] as Map<String, dynamic>?,
      pricing: pricingJson is Map<String, dynamic>
          ? _parsePricing(pricingJson)
          : null,
    );
  }

  static AuctionPricingEntity _parsePricing(Map<String, dynamic> json) {
    return AuctionPricingEntity(
      coinsPerPriceUnit: _optionalD(json['coinsPerPriceUnit']),
      commissionPercent: _optionalD(json['commissionPercent']),
      currencyCode: json['currencyCode']?.toString(),
      targetPrice: _optionalD(json['targetPrice']),
      targetPriceCoins: _optionalD(json['targetPriceCoins']),
      remainingCoins: _optionalD(json['remainingCoins']),
      remainingPrice: _optionalD(json['remainingPrice']),
      progressPercent: _optionalD(json['progressPercent']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static double? _optionalD(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
