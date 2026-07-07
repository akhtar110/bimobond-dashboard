/// Nested `auction` object for `POST /posts` when [CreatePostEntity.isAuctionable].
enum AuctionPricingMode { money, coins }

/// Nested `auction` object for `POST /posts` when [CreatePostEntity.isAuctionable].
class CreatePostAuctionEntity {
  const CreatePostAuctionEntity({
    this.itemName = '',
    this.itemImageUrl = '',
    this.pricingMode = AuctionPricingMode.money,
    this.startingPriceCoins,
    this.targetPriceCoins,
    this.startingPrice,
    this.targetPrice,
    this.currencyCode = 'USD',
    this.startedAt,
    this.endedAt,
  });

  final String itemName;
  final String itemImageUrl;
  final AuctionPricingMode pricingMode;
  final double? startingPriceCoins;
  final double? targetPriceCoins;
  final double? startingPrice;
  final double? targetPrice;
  final String currencyCode;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isMoneyMode => pricingMode == AuctionPricingMode.money;

  bool get hasValidPricing {
    if (isMoneyMode) {
      return targetPrice != null &&
          targetPrice! > 0 &&
          currencyCode.trim().length == 3;
    }
    return targetPriceCoins != null && targetPriceCoins! > 0;
  }

  bool get isComplete =>
      itemName.trim().isNotEmpty &&
      hasValidPricing &&
      (isMoneyMode ? (startingPrice ?? 0) : (startingPriceCoins ?? 0)) >= 0 &&
      startedAt != null &&
      endedAt != null &&
      endedAt!.isAfter(startedAt!) &&
      _targetMeetsStarting();

  bool _targetMeetsStarting() {
    if (isMoneyMode) {
      final start = startingPrice ?? 0;
      return (targetPrice ?? 0) >= start;
    }
    return targetPriceCoins! >= (startingPriceCoins ?? 0);
  }

  CreatePostAuctionEntity copyWith({
    String? itemName,
    String? itemImageUrl,
    AuctionPricingMode? pricingMode,
    double? startingPriceCoins,
    double? targetPriceCoins,
    double? startingPrice,
    double? targetPrice,
    String? currencyCode,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearStartingPriceCoins = false,
    bool clearTargetPriceCoins = false,
    bool clearStartingPrice = false,
    bool clearTargetPrice = false,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
  }) {
    return CreatePostAuctionEntity(
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      pricingMode: pricingMode ?? this.pricingMode,
      startingPriceCoins: clearStartingPriceCoins
          ? null
          : (startingPriceCoins ?? this.startingPriceCoins),
      targetPriceCoins:
          clearTargetPriceCoins ? null : (targetPriceCoins ?? this.targetPriceCoins),
      startingPrice:
          clearStartingPrice ? null : (startingPrice ?? this.startingPrice),
      targetPrice: clearTargetPrice ? null : (targetPrice ?? this.targetPrice),
      currencyCode: currencyCode ?? this.currencyCode,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    );
  }
}
