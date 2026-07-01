class AuctionUpdateEntity {
  const AuctionUpdateEntity({
    required this.auctionId,
    required this.currentTotalCoins,
    required this.targetPriceCoins,
    required this.status,
    this.winnerId,
    this.lastGift,
  });

  final String auctionId;
  final double currentTotalCoins;
  final double targetPriceCoins;
  final String status;
  final String? winnerId;
  final Map<String, dynamic>? lastGift;

  String? get lastGiftName => lastGift?['name'] as String?;
  String? get lastGiftThumbnail => lastGift?['thumbnailUrl'] as String?;

  factory AuctionUpdateEntity.fromJson(Map<String, dynamic> json) {
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
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
