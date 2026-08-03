import '../../../post_management/domain/entities/post_media_entity.dart';
import '../../../../core/utils/media_url_resolver.dart';
import 'auction_status.dart';
import 'gift_transaction_entity.dart';

/// Lightweight post snapshot returned with auction list/detail APIs.
class AuctionPostSummary {
  const AuctionPostSummary({
    this.id,
    this.description,
    this.thumbnailUrl,
    this.media = const [],
  });

  final String? id;
  final String? description;
  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
}

/// Lightweight live snapshot returned with auction list/detail APIs.
class AuctionLiveSummary {
  const AuctionLiveSummary({
    required this.id,
    this.title,
    this.status,
  });

  final String id;
  final String? title;
  final String? status;
}

/// Nested `counts` from admin list/detail responses.
class AuctionCounts {
  const AuctionCounts({
    this.bids = 0,
    this.giftTransactions = 0,
  });

  final int bids;
  final int giftTransactions;
}

/// Server-computed pricing breakdown on auction responses.
class AuctionPricingEntity {
  const AuctionPricingEntity({
    this.coinsPerPriceUnit,
    this.commissionPercent,
    this.currencyCode,
    this.targetPrice,
    this.targetPriceCoins,
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
  final double? targetPriceCoins;
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
    this.escrowEnabled = false,
    this.fulfillmentStatus,
    this.winnerId,
    required this.startedAt,
    this.endedAt,
    this.host,
    this.winner,
    this.giftTransactions,
    this.post,
    this.live,
    this.pricing,
    this.counts,
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
  final String status;
  final bool escrowEnabled;
  final String? fulfillmentStatus;
  final String? winnerId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? host;
  final Map<String, dynamic>? winner;
  final List<GiftTransactionEntity>? giftTransactions;
  final AuctionPostSummary? post;
  final AuctionLiveSummary? live;
  final AuctionPricingEntity? pricing;
  final AuctionCounts? counts;

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

  AuctionStatus get auctionStatus => AuctionStatus.parse(status);

  /// Coin goal for progress UI — nested pricing wins when the server sends it.
  double get effectiveTargetPriceCoins {
    final nested = pricing?.targetPriceCoins;
    if (nested != null && nested > 0) return nested;
    return targetPriceCoins;
  }

  /// Progress as 0.0–1.0 for progress bars from raised vs effective coin goal.
  double get progressFraction {
    final target = effectiveTargetPriceCoins;
    if (target > 0) {
      return (currentTotalCoins / target).clamp(0.0, 1.0);
    }
    final fromPricing = pricing?.progressPercent;
    if (fromPricing != null) {
      final normalized = fromPricing > 1 ? fromPricing / 100 : fromPricing;
      return normalized.clamp(0.0, 1.0);
    }
    return 0;
  }

  /// Remaining coins toward the effective coin goal.
  double get remainingCoins {
    final target = effectiveTargetPriceCoins;
    if (target > 0) {
      return (target - currentTotalCoins).clamp(0, double.infinity);
    }
    return pricing?.remainingCoins ?? 0;
  }

  bool get isActive => status == AuctionStatus.active.apiValue;
  bool get isCompleted => status == AuctionStatus.completed.apiValue;
  bool get isSettled => status == AuctionStatus.settled.apiValue;
  bool get isCancelled => status == AuctionStatus.cancelled.apiValue;
  bool get isBanned => status == AuctionStatus.banned.apiValue;
  bool get isDisputed => status == AuctionStatus.disputed.apiValue;

  bool get hasWinner =>
      (winnerId != null && winnerId!.trim().isNotEmpty) || winner != null;

  bool get hasPost =>
      (postId != null && postId!.trim().isNotEmpty) || post != null;

  bool get hasLive =>
      (liveId != null && liveId!.trim().isNotEmpty) || live != null;

  /// Gift count from nested `counts`, else loaded gift transactions.
  int get giftTransactionCount =>
      counts?.giftTransactions ?? giftTransactions?.length ?? 0;

  int get bidCount => counts?.bids ?? 0;

  /// Admin PATCH is rejected for SETTLED. BANNED requires unban first.
  /// CANCELLED can be edited (reactivates to ACTIVE per admin API).
  bool get isAdminEditable => !isSettled && !isBanned;

  /// Cancel / ban allowed for ACTIVE, COMPLETED, and DISPUTED.
  bool get canAdminCancelOrBan =>
      isActive || isCompleted || isDisputed;

  /// Unban is BANNED-only.
  bool get canAdminUnban => isBanned;

  /// Force resolve is ACTIVE-only.
  bool get canAdminForceResolve => isActive;

  /// Show escrow panel when escrow is enabled (actions gated separately).
  bool get showEscrowFulfillmentTools => effectiveEscrowEnabled;

  /// True when the API marks escrow on, or fulfillment/coins imply escrow flow.
  bool get effectiveEscrowEnabled =>
      escrowEnabled ||
      hasFulfillmentLifecycle ||
      ((isCompleted || isDisputed) && currentTotalCoins > 0);

  bool get hasFulfillmentLifecycle {
    final value = fulfillmentStatus?.trim().toUpperCase();
    return value != null && value.isNotEmpty && value != 'NONE';
  }

  /// Escrow refund (`PATCH .../fulfillment/refund`).
  bool get canAdminRefundEscrow =>
      effectiveEscrowEnabled &&
      (isCompleted || isDisputed) &&
      !isCancelled &&
      !isBanned &&
      !isSettled;

  /// Escrow release (`PATCH .../fulfillment/release`).
  bool get canAdminReleaseEscrow =>
      canAdminRefundEscrow && currentTotalCoins > 0;

  /// Whether a host may edit auction details (ACTIVE only).
  bool get isHostEditable => isActive;

  AuctionEntity copyWith({
    String? itemName,
    String? itemImageUrl,
    String? postId,
    String? liveId,
    double? startingPriceCoins,
    double? targetPriceCoins,
    double? startingPrice,
    double? targetPrice,
    String? currencyCode,
    double? currentTotalCoins,
    String? status,
    bool? escrowEnabled,
    String? fulfillmentStatus,
    String? winnerId,
    DateTime? startedAt,
    DateTime? endedAt,
    Map<String, dynamic>? host,
    Map<String, dynamic>? winner,
    List<GiftTransactionEntity>? giftTransactions,
    AuctionPostSummary? post,
    AuctionLiveSummary? live,
    AuctionPricingEntity? pricing,
    AuctionCounts? counts,
  }) {
    return AuctionEntity(
      id: id,
      postId: postId ?? this.postId,
      liveId: liveId ?? this.liveId,
      hostId: hostId,
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      startingPriceCoins: startingPriceCoins ?? this.startingPriceCoins,
      targetPriceCoins: targetPriceCoins ?? this.targetPriceCoins,
      startingPrice: startingPrice ?? this.startingPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      currencyCode: currencyCode ?? this.currencyCode,
      currentTotalCoins: currentTotalCoins ?? this.currentTotalCoins,
      status: status ?? this.status,
      escrowEnabled: escrowEnabled ?? this.escrowEnabled,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      winnerId: winnerId ?? this.winnerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      host: host ?? this.host,
      winner: winner ?? this.winner,
      giftTransactions: giftTransactions ?? this.giftTransactions,
      post: post ?? this.post,
      live: live ?? this.live,
      pricing: pricing ?? this.pricing,
      counts: counts ?? this.counts,
    );
  }

  /// Admin list rows include escrow fields that public detail may omit.
  AuctionEntity mergeAdminListPreview(AuctionEntity preview) {
    if (preview.id != id) return this;
    return copyWith(
      escrowEnabled: escrowEnabled || preview.escrowEnabled,
      fulfillmentStatus: fulfillmentStatus ?? preview.fulfillmentStatus,
      currentTotalCoins: currentTotalCoins > 0
          ? currentTotalCoins
          : preview.currentTotalCoins,
      counts: counts ?? preview.counts,
      post: post ?? preview.post,
      live: live ?? preview.live,
      host: host ?? preview.host,
      winner: winner ?? preview.winner,
    );
  }
}
