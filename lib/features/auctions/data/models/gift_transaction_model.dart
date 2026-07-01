import '../../domain/entities/gift_transaction_entity.dart';

class GiftTransactionModel extends GiftTransactionEntity {
  const GiftTransactionModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.giftId,
    super.postId,
    super.liveId,
    super.auctionId,
    required super.priceCoins,
    required super.contributionCoins,
    required super.createdAt,
    super.sender,
    super.gift,
  });

  factory GiftTransactionModel.fromJson(Map<String, dynamic> json) {
    return GiftTransactionModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      giftId: json['giftId']?.toString() ?? '',
      postId: json['postId'] as String?,
      liveId: json['liveId'] as String?,
      auctionId: json['auctionId'] as String?,
      priceCoins: _toDouble(json['priceCoins'] ?? json['priceUsd']),
      contributionCoins:
          _toDouble(json['contributionCoins'] ?? json['contributionUsd']),
      createdAt: _toDate(json['createdAt']),
      sender: json['sender'] as Map<String, dynamic>?,
      gift: json['gift'] as Map<String, dynamic>?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _toDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
