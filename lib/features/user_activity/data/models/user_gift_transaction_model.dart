import '../../domain/entities/user_gift_transaction_entity.dart';

class UserGiftTransactionModel extends UserGiftTransactionEntity {
  const UserGiftTransactionModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.giftId,
    super.postId,
    super.liveId,
    super.auctionId,
    required super.priceUsd,
    required super.contributionUsd,
    required super.createdAt,
    super.gift,
    super.sender,
    super.receiver,
  });

  factory UserGiftTransactionModel.fromJson(Map<String, dynamic> json) {
    return UserGiftTransactionModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      giftId: json['giftId']?.toString() ?? '',
      postId: json['postId'] as String?,
      liveId: json['liveId'] as String?,
      auctionId: json['auctionId'] as String?,
      priceUsd: _d(json['priceUsd']),
      contributionUsd: _d(json['contributionUsd']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      gift: json['gift'] as Map<String, dynamic>?,
      sender: json['sender'] as Map<String, dynamic>?,
      receiver: json['receiver'] as Map<String, dynamic>?,
    );
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
