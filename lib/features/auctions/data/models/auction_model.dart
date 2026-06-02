import '../../domain/entities/auction_entity.dart';
import 'gift_transaction_model.dart';

class AuctionModel extends AuctionEntity {
  const AuctionModel({
    required super.id,
    super.postId,
    super.liveId,
    required super.hostId,
    super.itemName,
    super.itemImageUrl,
    required super.startingPriceUsd,
    required super.targetPriceUsd,
    required super.currentTotalUsd,
    required super.status,
    super.winnerId,
    required super.startedAt,
    super.endedAt,
    super.host,
    super.winner,
    super.giftTransactions,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final rawTx = json['giftTransactions'] as List?;

    return AuctionModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId'] as String?,
      liveId: json['liveId'] as String?,
      hostId: json['hostId']?.toString() ?? '',
      itemName: json['itemName'] as String?,
      itemImageUrl: json['itemImageUrl'] as String?,
      startingPriceUsd: _d(json['startingPriceUsd']),
      targetPriceUsd: _d(json['targetPriceUsd']),
      currentTotalUsd: _d(json['currentTotalUsd']),
      status: json['status']?.toString() ?? 'ACTIVE',
      winnerId: json['winnerId'] as String?,
      startedAt: _date(json['startedAt']),
      endedAt: json['endedAt'] != null ? _date(json['endedAt']) : null,
      host: json['host'] as Map<String, dynamic>?,
      winner: json['winner'] as Map<String, dynamic>?,
      giftTransactions: rawTx
          ?.map((e) => GiftTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
