import '../../domain/entities/create_post_auction_entity.dart';

class CreateAuctionDto {
  const CreateAuctionDto({
    required this.itemName,
    required this.itemImageUrl,
    required this.startingPriceUsd,
    required this.targetPriceUsd,
    required this.startedAt,
    required this.endedAt,
  });

  final String itemName;
  final String itemImageUrl;
  final double startingPriceUsd;
  final double targetPriceUsd;
  final String startedAt;
  final String endedAt;

  factory CreateAuctionDto.fromEntity(CreatePostAuctionEntity entity) {
    return CreateAuctionDto(
      itemName: entity.itemName,
      itemImageUrl: entity.itemImageUrl,
      startingPriceUsd: entity.startingPriceUsd!,
      targetPriceUsd: entity.targetPriceUsd!,
      startedAt: entity.startedAt!.toUtc().toIso8601String(),
      endedAt: entity.endedAt!.toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'itemImageUrl': itemImageUrl,
        'startingPriceUsd': startingPriceUsd,
        'targetPriceUsd': targetPriceUsd,
        'startedAt': startedAt,
        'endedAt': endedAt,
      };
}
