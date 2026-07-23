import '../enums/gift_size.dart';

class GiftEntity {
  const GiftEntity({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.animationUrl,
    required this.priceCoins,
    required this.size,
    required this.isActive,
    this.publishedAt,
  });

  final String id;
  final String name;
  final String thumbnailUrl;
  final String? animationUrl;
  final double priceCoins;
  final GiftSize size;
  final bool isActive;
  final DateTime? publishedAt;

  GiftEntity copyWith({
    String? name,
    String? thumbnailUrl,
    String? animationUrl,
    double? priceCoins,
    GiftSize? size,
    bool? isActive,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) {
    return GiftEntity(
      id: id,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      priceCoins: priceCoins ?? this.priceCoins,
      size: size ?? this.size,
      isActive: isActive ?? this.isActive,
      publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
    );
  }
}
