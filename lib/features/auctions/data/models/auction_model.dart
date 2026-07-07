import '../../../../core/utils/media_url_resolver.dart';
import '../../../post_management/domain/entities/post_media_entity.dart';
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
    required super.startingPriceCoins,
    required super.targetPriceCoins,
    super.startingPrice,
    super.targetPrice,
    super.currencyCode,
    required super.currentTotalCoins,
    required super.status,
    super.winnerId,
    required super.startedAt,
    super.endedAt,
    super.host,
    super.winner,
    super.giftTransactions,
    super.post,
    super.pricing,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawTx = map['giftTransactions'] as List?;
    final postSummary =
        _parsePostSummary(map['post']) ?? _parsePostSummaryFromRoot(map);

    var itemImageUrl = _resolveItemImageUrl(map);
    if ((itemImageUrl == null || itemImageUrl.isEmpty) && postSummary != null) {
      itemImageUrl = resolvePostDisplayThumbnailUrl(
        media: postSummary.media,
        thumbnailUrl: postSummary.thumbnailUrl,
      );
    }

    final pricingJson = map['pricing'];
    return AuctionModel(
      id: map['id']?.toString() ?? '',
      postId: map['postId']?.toString(),
      liveId: map['liveId']?.toString(),
      hostId: map['hostId']?.toString() ?? '',
      itemName: map['itemName']?.toString(),
      itemImageUrl: itemImageUrl,
      startingPriceCoins: _d(map['startingPriceCoins'] ?? map['startingPriceUsd']),
      targetPriceCoins: _d(map['targetPriceCoins'] ?? map['targetPriceUsd']),
      startingPrice: _optionalD(map['startingPrice']),
      targetPrice: _optionalD(map['targetPrice'] ?? map['targetFiatUsd']),
      currencyCode: map['currencyCode']?.toString(),
      currentTotalCoins: _d(map['currentTotalCoins'] ?? map['currentTotalUsd']),
      status: map['status']?.toString() ?? 'ACTIVE',
      winnerId: map['winnerId']?.toString(),
      startedAt: _date(map['startedAt']),
      endedAt: map['endedAt'] != null ? _date(map['endedAt']) : null,
      host: map['host'] is Map
          ? Map<String, dynamic>.from(map['host'] as Map)
          : null,
      winner: map['winner'] is Map
          ? Map<String, dynamic>.from(map['winner'] as Map)
          : null,
      giftTransactions: rawTx
          ?.map((e) => GiftTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      post: postSummary,
      pricing: pricingJson is Map<String, dynamic>
          ? _parsePricing(pricingJson)
          : null,
    );
  }

  static AuctionPricingEntity _parsePricing(Map<String, dynamic> json) {
    return AuctionPricingEntity(
      coinsPerPriceUnit: _optionalD(json['coinsPerPriceUnit'] ?? json['coinsPerUsd']),
      commissionPercent: _optionalD(json['commissionPercent']),
      currencyCode: json['currencyCode']?.toString(),
      targetPrice: _optionalD(json['targetPrice']),
      targetPriceCoins: _optionalD(json['targetPriceCoins']),
      startingPrice: _optionalD(json['startingPrice']),
      estimatedHostEarningsCoins:
          _optionalD(json['estimatedHostEarningsCoins']),
      estimatedHostEarningsPrice:
          _optionalD(json['estimatedHostEarningsPrice'] ?? json['estimatedHostEarningsFiatUsd']),
      estimatedBidderSpendCoins:
          _optionalD(json['estimatedBidderSpendCoins']),
      estimatedBidderSpendPrice:
          _optionalD(json['estimatedBidderSpendPrice'] ?? json['estimatedBidderSpendFiatUsd']),
      remainingCoins: _optionalD(json['remainingCoins']),
      remainingPrice: _optionalD(json['remainingPrice'] ?? json['remainingFiatUsd']),
      progressPercent: _optionalD(json['progressPercent']),
    );
  }

  static String? _resolveItemImageUrl(Map<String, dynamic> json) {
    for (final key in ['itemImageUrl', 'itemImage', 'imageUrl', 'image']) {
      final resolved = resolveMediaUrl(json[key]?.toString());
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return null;
  }

  static AuctionPostSummary? _parsePostSummaryFromRoot(
    Map<String, dynamic> json,
  ) {
    final thumb = resolveMediaUrl(
      json['postThumbnailUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
    );
    final media = PostMediaEntity.listFromJson(
      json['postMedia'] ?? json['media'],
    );
    if ((thumb == null || thumb.isEmpty) && media.isEmpty) return null;
    return AuctionPostSummary(
      thumbnailUrl: thumb,
      media: media,
    );
  }

  static AuctionPostSummary? _parsePostSummary(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final thumbnail = resolveMediaUrl(
      m['thumbnailUrl']?.toString() ?? m['thumbnail']?.toString(),
    );
    final media = PostMediaEntity.listFromJson(m['media']);
    if ((thumbnail == null || thumbnail.isEmpty) && media.isEmpty) {
      return null;
    }
    return AuctionPostSummary(
      thumbnailUrl: thumbnail,
      media: media,
    );
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static double? _optionalD(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
