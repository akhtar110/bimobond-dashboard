/// Partial update body for `PATCH /auctions/:id` and `PATCH /auctions/admin/:id`.
class AuctionUpdateBody {
  const AuctionUpdateBody({
    this.itemName,
    this.itemImageUrl,
    this.postId,
    this.liveId,
    this.targetPrice,
    this.targetPriceCoins,
    this.startingPrice,
    this.startingPriceCoins,
    this.currencyCode,
    this.startedAt,
    this.endedAt,
    this.status,
  });

  final String? itemName;
  final String? itemImageUrl;
  final String? postId;
  final String? liveId;
  final double? targetPrice;
  final double? targetPriceCoins;
  final double? startingPrice;
  final double? startingPriceCoins;
  final String? currencyCode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? status;

  bool get isEmpty =>
      itemName == null &&
      itemImageUrl == null &&
      postId == null &&
      liveId == null &&
      targetPrice == null &&
      targetPriceCoins == null &&
      startingPrice == null &&
      startingPriceCoins == null &&
      currencyCode == null &&
      startedAt == null &&
      endedAt == null &&
      status == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (itemName != null) map['itemName'] = itemName;
    if (itemImageUrl != null) map['itemImageUrl'] = itemImageUrl;
    if (postId != null) map['postId'] = postId;
    if (liveId != null) map['liveId'] = liveId;
    if (targetPrice != null) map['targetPrice'] = targetPrice;
    if (targetPriceCoins != null) map['targetPriceCoins'] = targetPriceCoins;
    if (startingPrice != null) map['startingPrice'] = startingPrice;
    if (startingPriceCoins != null) {
      map['startingPriceCoins'] = startingPriceCoins;
    }
    if (currencyCode != null) map['currencyCode'] = currencyCode;
    if (startedAt != null) {
      map['startedAt'] = startedAt!.toUtc().toIso8601String();
    }
    if (endedAt != null) {
      map['endedAt'] = endedAt!.toUtc().toIso8601String();
    }
    if (status != null) map['status'] = status;
    return map;
  }

  /// Builds a PATCH body containing only fields that differ from [original].
  factory AuctionUpdateBody.diff({
    required AuctionSnapshot original,
    String? itemName,
    String? itemImageUrl,
    String? postId,
    String? liveId,
    double? targetPrice,
    double? targetPriceCoins,
    double? startingPrice,
    double? startingPriceCoins,
    String? currencyCode,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
  }) {
    String? changedString(String? next, String? prev) {
      final n = next?.trim();
      if (n == null) return null;
      if (n == (prev ?? '').trim()) return null;
      return n;
    }

    double? changedDouble(double? next, double? prev) {
      if (next == null) return null;
      if (prev != null && (next - prev).abs() < 0.000001) return null;
      return next;
    }

    DateTime? changedDate(DateTime? next, DateTime? prev) {
      if (next == null) return null;
      if (prev != null && next.isAtSameMomentAs(prev)) return null;
      return next;
    }

    return AuctionUpdateBody(
      itemName: changedString(itemName, original.itemName),
      itemImageUrl: changedString(itemImageUrl, original.itemImageUrl),
      postId: changedString(postId, original.postId),
      liveId: changedString(liveId, original.liveId),
      targetPrice: changedDouble(targetPrice, original.targetPrice),
      targetPriceCoins: changedDouble(targetPriceCoins, original.targetPriceCoins),
      startingPrice: changedDouble(startingPrice, original.startingPrice),
      startingPriceCoins:
          changedDouble(startingPriceCoins, original.startingPriceCoins),
      currencyCode: changedString(currencyCode, original.currencyCode),
      startedAt: changedDate(startedAt, original.startedAt),
      endedAt: changedDate(endedAt, original.endedAt),
      status: changedString(status, original.status),
    );
  }
}

/// Snapshot of auction fields that can be edited via PATCH.
class AuctionSnapshot {
  const AuctionSnapshot({
    this.itemName,
    this.itemImageUrl,
    this.postId,
    this.liveId,
    this.targetPrice,
    this.targetPriceCoins,
    this.startingPrice,
    this.startingPriceCoins,
    this.currencyCode,
    this.startedAt,
    this.endedAt,
    this.status,
  });

  final String? itemName;
  final String? itemImageUrl;
  final String? postId;
  final String? liveId;
  final double? targetPrice;
  final double? targetPriceCoins;
  final double? startingPrice;
  final double? startingPriceCoins;
  final String? currencyCode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? status;

  factory AuctionSnapshot.fromEntity(dynamic auction) {
    return AuctionSnapshot(
      itemName: auction.itemName as String?,
      itemImageUrl: auction.itemImageUrl as String?,
      postId: auction.postId as String?,
      liveId: auction.liveId as String?,
      targetPrice: auction.targetPrice as double?,
      targetPriceCoins: auction.targetPriceCoins as double,
      startingPrice: auction.startingPrice as double?,
      startingPriceCoins: auction.startingPriceCoins as double,
      currencyCode: auction.currencyCode as String?,
      startedAt: auction.startedAt as DateTime,
      endedAt: auction.endedAt as DateTime?,
      status: auction.status as String?,
    );
  }
}
