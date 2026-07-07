import '../../domain/entities/create_post_auction_entity.dart';

class CreateAuctionDto {
  const CreateAuctionDto({
    required this.itemName,
    required this.startedAt,
    required this.endedAt,
    required this.pricingMode,
    this.startingPriceCoins,
    this.targetPriceCoins,
    this.startingPrice,
    this.targetPrice,
    this.currencyCode,
  });

  final String itemName;
  final AuctionPricingMode pricingMode;
  final double? startingPriceCoins;
  final double? targetPriceCoins;
  final double? startingPrice;
  final double? targetPrice;
  final String? currencyCode;
  final String startedAt;
  final String endedAt;

  factory CreateAuctionDto.fromEntity(CreatePostAuctionEntity entity) {
    final isMoney = entity.isMoneyMode;
    return CreateAuctionDto(
      itemName: entity.itemName,
      pricingMode: entity.pricingMode,
      startingPriceCoins: isMoney ? null : (entity.startingPriceCoins ?? 0),
      targetPriceCoins: isMoney ? null : entity.targetPriceCoins,
      startingPrice: isMoney ? entity.startingPrice : null,
      targetPrice: isMoney ? entity.targetPrice : null,
      currencyCode: isMoney ? entity.currencyCode : null,
      startedAt: entity.startedAt!.toUtc().toIso8601String(),
      endedAt: entity.endedAt!.toUtc().toIso8601String(),
    );
  }

  /// Image is taken from the post media uploaded with the post — not sent here.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'itemName': itemName,
      'startedAt': startedAt,
      'endedAt': endedAt,
    };
    if (pricingMode == AuctionPricingMode.coins && targetPriceCoins != null) {
      map['startingPriceCoins'] = startingPriceCoins ?? 0;
      map['targetPriceCoins'] = targetPriceCoins;
    } else if (pricingMode == AuctionPricingMode.money && targetPrice != null) {
      map['targetPrice'] = targetPrice;
      map['currencyCode'] = currencyCode ?? 'USD';
      if (startingPrice != null && startingPrice! > 0) {
        map['startingPrice'] = startingPrice;
      }
    }
    return map;
  }
}
