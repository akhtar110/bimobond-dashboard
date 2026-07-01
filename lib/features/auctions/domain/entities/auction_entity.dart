import '../../../post_management/domain/entities/post_media_entity.dart';
import '../../../../core/utils/media_url_resolver.dart';
import 'gift_transaction_entity.dart';

/// Lightweight post snapshot returned with auction list/detail APIs.
class AuctionPostSummary {
  const AuctionPostSummary({
    this.thumbnailUrl,
    this.media = const [],
  });

  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
}

/// Server-computed pricing breakdown on auction responses.
class AuctionPricingEntity {
  const AuctionPricingEntity({
    this.coinsPerPriceUnit,
    this.commissionPercent,
    this.currencyCode,
    this.targetPrice,
    this.startingPrice,
    this.estimatedHostEarningsCoins,
    this.estimatedHostEarningsPrice,
    this.estimatedBidderSpendCoins,
    this.estimatedBidderSpendPrice,
    this.remainingCoins,
    this.remainingPrice,
    this.progressPercent,
  });

  final double? coinsPerPriceUnit;
  final double? commissionPercent;
  final String? currencyCode;
  final double? targetPrice;
  final double? startingPrice;
  final double? estimatedHostEarningsCoins;
  final double? estimatedHostEarningsPrice;
  final double? estimatedBidderSpendCoins;
  final double? estimatedBidderSpendPrice;
  final double? remainingCoins;
  final double? remainingPrice;
  final double? progressPercent;
}

String? resolveAuctionDisplayImageUrl({
  String? itemImageUrl,
  AuctionPostSummary? post,
}) {
  if (post != null) {
    final fromPost = resolvePostDisplayThumbnailUrl(
      media: post.media,
      thumbnailUrl: post.thumbnailUrl,
    );
    if (fromPost != null && fromPost.isNotEmpty) return fromPost;
  }

  final resolvedItem = resolveMediaUrl(itemImageUrl);
  if (resolvedItem != null && resolvedItem.isNotEmpty) return resolvedItem;
  return null;
}

class AuctionEntity {
  const AuctionEntity({
    required this.id,
    this.postId,
    this.liveId,
    required this.hostId,
    this.itemName,
    this.itemImageUrl,
    required this.startingPriceCoins,
    required this.targetPriceCoins,
    this.startingPrice,
    this.targetPrice,
    this.currencyCode,
    required this.currentTotalCoins,
    required this.status,
    this.winnerId,
    required this.startedAt,
    this.endedAt,
    this.host,
    this.winner,
    this.giftTransactions,
    this.post,
    this.pricing,
  });

  final String id;
  final String? postId;
  final String? liveId;
  final String hostId;
  final String? itemName;
  final String? itemImageUrl;
  final double startingPriceCoins;
  final double targetPriceCoins;
  final double? startingPrice;
  final double? targetPrice;
  final String? currencyCode;
  final double currentTotalCoins;
  final String status; // ACTIVE | COMPLETED | CANCELLED
  final String? winnerId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? host;
  final Map<String, dynamic>? winner;
  final List<GiftTransactionEntity>? giftTransactions;
  final AuctionPostSummary? post;
  final AuctionPricingEntity? pricing;

  /// Post-attached media from the linked post, then [itemImageUrl] fallback.
  String? get displayImageUrl =>
      resolveAuctionDisplayImageUrl(itemImageUrl: itemImageUrl, post: post);

  bool get hasMoneyTarget =>
      targetPrice != null && (currencyCode?.isNotEmpty ?? false);

  // Convenience getters
  String get hostName =>
      host?['username'] as String? ?? host?['name'] as String? ?? hostId;
  String? get hostAvatar => host?['avatarUrl'] as String?;
  String? get winnerName =>
      winner?['username'] as String? ?? winner?['name'] as String?;
  String? get winnerAvatar => winner?['avatarUrl'] as String?;

  double get progressPercent => targetPriceCoins > 0
      ? (currentTotalCoins / targetPriceCoins).clamp(0, 1)
      : 0;

  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  AuctionEntity copyWith({
    double? currentTotalCoins,
    String? status,
    String? winnerId,
    DateTime? endedAt,
    Map<String, dynamic>? winner,
    List<GiftTransactionEntity>? giftTransactions,
  }) {
    return AuctionEntity(
      id: id,
      postId: postId,
      liveId: liveId,
      hostId: hostId,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      startingPriceCoins: startingPriceCoins,
      targetPriceCoins: targetPriceCoins,
      startingPrice: startingPrice,
      targetPrice: targetPrice,
      currencyCode: currencyCode,
      currentTotalCoins: currentTotalCoins ?? this.currentTotalCoins,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      host: host,
      winner: winner ?? this.winner,
      giftTransactions: giftTransactions ?? this.giftTransactions,
      post: post,
      pricing: pricing,
    );
  }
}
