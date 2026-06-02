class AuctionUpdateEntity {
  const AuctionUpdateEntity({
    required this.auctionId,
    required this.currentTotalUsd,
    required this.targetPriceUsd,
    required this.status,
    this.winnerId,
    this.lastGift,
  });

  final String auctionId;
  final double currentTotalUsd;
  final double targetPriceUsd;
  final String status;
  final String? winnerId;
  final Map<String, dynamic>? lastGift;

  String? get lastGiftName => lastGift?['name'] as String?;
  String? get lastGiftThumbnail => lastGift?['thumbnailUrl'] as String?;

  factory AuctionUpdateEntity.fromJson(Map<String, dynamic> json) {
    return AuctionUpdateEntity(
      auctionId: json['auctionId']?.toString() ?? '',
      currentTotalUsd: _toDouble(json['currentTotalUsd']),
      targetPriceUsd: _toDouble(json['targetPriceUsd']),
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
