/// Nested `auction` object for `POST /posts` when [CreatePostEntity.isAuctionable].
class CreatePostAuctionEntity {
  const CreatePostAuctionEntity({
    this.itemName = '',
    this.itemImageUrl = '',
    this.startingPriceUsd,
    this.targetPriceUsd,
    this.startedAt,
    this.endedAt,
  });

  final String itemName;
  final String itemImageUrl;
  final double? startingPriceUsd;
  final double? targetPriceUsd;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isComplete =>
      itemName.trim().isNotEmpty &&
      startingPriceUsd != null &&
      startingPriceUsd! > 0 &&
      targetPriceUsd != null &&
      targetPriceUsd! > 0 &&
      startedAt != null &&
      endedAt != null &&
      endedAt!.isAfter(startedAt!);

  CreatePostAuctionEntity copyWith({
    String? itemName,
    String? itemImageUrl,
    double? startingPriceUsd,
    double? targetPriceUsd,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
  }) {
    return CreatePostAuctionEntity(
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      startingPriceUsd: startingPriceUsd ?? this.startingPriceUsd,
      targetPriceUsd: targetPriceUsd ?? this.targetPriceUsd,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    );
  }
}
