import '../../../post_management/domain/entities/post_media_entity.dart';
import '../../../../core/utils/media_url_resolver.dart';
import 'gift_transaction_entity.dart';

/// Lightweight post snapshot returned with auction list/detail APIs.
class AuctionPostSummary {
  const AuctionPostSummary({
    this.thumbnailUrl,
    this.media = const [],
  });

  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
}

String? resolveAuctionDisplayImageUrl({
  String? itemImageUrl,
  AuctionPostSummary? post,
}) {
  if (post != null) {
    final fromPost = resolvePostDisplayThumbnailUrl(
      media: post.media,
      thumbnailUrl: post.thumbnailUrl,
    );
    if (fromPost != null && fromPost.isNotEmpty) return fromPost;
  }

  final resolvedItem = resolveMediaUrl(itemImageUrl);
  if (resolvedItem != null && resolvedItem.isNotEmpty) return resolvedItem;
  return null;
}

class AuctionEntity {
  const AuctionEntity({
    required this.id,
    this.postId,
    this.liveId,
    required this.hostId,
    this.itemName,
    this.itemImageUrl,
    required this.startingPriceUsd,
    required this.targetPriceUsd,
    required this.currentTotalUsd,
    required this.status,
    this.winnerId,
    required this.startedAt,
    this.endedAt,
    this.host,
    this.winner,
    this.giftTransactions,
    this.post,
  });

  final String id;
  final String? postId;
  final String? liveId;
  final String hostId;
  final String? itemName;
  final String? itemImageUrl;
  final double startingPriceUsd;
  final double targetPriceUsd;
  final double currentTotalUsd;
  final String status; // ACTIVE | COMPLETED | CANCELLED
  final String? winnerId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? host;
  final Map<String, dynamic>? winner;
  final List<GiftTransactionEntity>? giftTransactions;
  final AuctionPostSummary? post;

  /// Post-attached media from the linked post, then [itemImageUrl] fallback.
  String? get displayImageUrl =>
      resolveAuctionDisplayImageUrl(itemImageUrl: itemImageUrl, post: post);

  // Convenience getters
  String get hostName =>
      host?['username'] as String? ?? host?['name'] as String? ?? hostId;
  String? get hostAvatar => host?['avatarUrl'] as String?;
  String? get winnerName =>
      winner?['username'] as String? ?? winner?['name'] as String?;
  String? get winnerAvatar => winner?['avatarUrl'] as String?;

  double get progressPercent =>
      targetPriceUsd > 0 ? (currentTotalUsd / targetPriceUsd).clamp(0, 1) : 0;

  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  AuctionEntity copyWith({
    double? currentTotalUsd,
    String? status,
    String? winnerId,
    DateTime? endedAt,
    Map<String, dynamic>? winner,
    List<GiftTransactionEntity>? giftTransactions,
  }) {
    return AuctionEntity(
      id: id,
      postId: postId,
      liveId: liveId,
      hostId: hostId,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      startingPriceUsd: startingPriceUsd,
      targetPriceUsd: targetPriceUsd,
      currentTotalUsd: currentTotalUsd ?? this.currentTotalUsd,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      host: host,
      winner: winner ?? this.winner,
      giftTransactions: giftTransactions ?? this.giftTransactions,
      post: post,
    );
  }
}
