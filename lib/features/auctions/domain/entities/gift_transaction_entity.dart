class GiftTransactionEntity {
  const GiftTransactionEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.giftId,
    this.postId,
    this.liveId,
    this.auctionId,
    required this.priceUsd,
    required this.contributionUsd,
    required this.createdAt,
    this.sender,
    this.gift,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String giftId;
  final String? postId;
  final String? liveId;
  final String? auctionId;
  final double priceUsd;
  final double contributionUsd;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? gift;

  String get senderName =>
      sender?['username'] as String? ?? sender?['name'] as String? ?? senderId;
  String? get senderAvatar => sender?['avatarUrl'] as String?;
  String? get giftName => gift?['name'] as String?;
  String? get giftThumbnail => gift?['thumbnailUrl'] as String?;
}
