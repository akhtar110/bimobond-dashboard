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
    super.escrowEnabled,
    super.fulfillmentStatus,
    super.winnerId,
    required super.startedAt,
    super.endedAt,
    super.host,
    super.winner,
    super.giftTransactions,
    super.post,
    super.live,
    super.pricing,
    super.counts,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawTx = map['giftTransactions'] as List?;
    final postSummary =
        _parsePostSummary(map['post']) ?? _parsePostSummaryFromRoot(map);
    final liveSummary =
        _parseLiveSummary(map['live']) ?? _liveFromId(map['liveId']?.toString());
    final counts = _parseCounts(map['counts']);

    var itemImageUrl = _resolveItemImageUrl(map);
    if ((itemImageUrl == null || itemImageUrl.isEmpty) && postSummary != null) {
      itemImageUrl = resolvePostDisplayThumbnailUrl(
        media: postSummary.media,
        thumbnailUrl: postSummary.thumbnailUrl,
      );
    }

    final pricingJson = map['pricing'];
    final postId = map['postId']?.toString() ?? postSummary?.id;
    final liveId = map['liveId']?.toString() ?? liveSummary?.id;
    final giftTransactions = rawTx
        ?.map((e) => GiftTransactionModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    return AuctionModel(
      id: map['id']?.toString() ?? map['auctionId']?.toString() ?? '',
      postId: postId,
      liveId: liveId,
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
      escrowEnabled: _parseBool(map['escrowEnabled']) ||
          _parseBool(map['escrow'] is Map
              ? (map['escrow'] as Map)['enabled']
              : null),
      fulfillmentStatus: map['fulfillmentStatus']?.toString() ??
          (map['fulfillment'] is Map
              ? (map['fulfillment'] as Map)['status']?.toString()
              : null),
      winnerId: map['winnerId']?.toString(),
      startedAt: _date(map['startedAt']),
      endedAt: map['endedAt'] != null ? _date(map['endedAt']) : null,
      host: map['host'] is Map
          ? Map<String, dynamic>.from(map['host'] as Map)
          : null,
      winner: map['winner'] is Map
          ? Map<String, dynamic>.from(map['winner'] as Map)
          : null,
      giftTransactions: giftTransactions,
      post: postSummary,
      live: liveSummary,
      pricing: pricingJson is Map<String, dynamic>
          ? _parsePricing(pricingJson)
          : null,
      counts: counts ??
          (giftTransactions != null
              ? AuctionCounts(giftTransactions: giftTransactions.length)
              : null),
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

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
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
    final id = m['id']?.toString();
    final description = m['description']?.toString();
    final thumbnail = resolveMediaUrl(
      m['thumbnailUrl']?.toString() ?? m['thumbnail']?.toString(),
    );
    final media = PostMediaEntity.listFromJson(m['media']);
    final hasMedia = (thumbnail != null && thumbnail.isNotEmpty) || media.isNotEmpty;
    final hasIdentity =
        (id != null && id.isNotEmpty) ||
        (description != null && description.trim().isNotEmpty);
    if (!hasMedia && !hasIdentity) return null;
    return AuctionPostSummary(
      id: id,
      description: description,
      thumbnailUrl: thumbnail,
      media: media,
    );
  }

  static AuctionLiveSummary? _parseLiveSummary(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return AuctionLiveSummary(
      id: id,
      title: m['title']?.toString(),
      status: m['status']?.toString(),
    );
  }

  static AuctionLiveSummary? _liveFromId(String? liveId) {
    if (liveId == null || liveId.isEmpty) return null;
    return AuctionLiveSummary(id: liveId);
  }

  static AuctionCounts? _parseCounts(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return AuctionCounts(
      bids: (m['bids'] as num?)?.toInt() ?? 0,
      giftTransactions: (m['giftTransactions'] as num?)?.toInt() ?? 0,
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
