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
    super.post,
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

    return AuctionModel(
      id: map['id']?.toString() ?? '',
      postId: map['postId']?.toString(),
      liveId: map['liveId']?.toString(),
      hostId: map['hostId']?.toString() ?? '',
      itemName: map['itemName']?.toString(),
      itemImageUrl: itemImageUrl,
      startingPriceUsd: _d(map['startingPriceUsd']),
      targetPriceUsd: _d(map['targetPriceUsd']),
      currentTotalUsd: _d(map['currentTotalUsd']),
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

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
