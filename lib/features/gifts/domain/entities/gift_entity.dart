class GiftEntity {
  const GiftEntity({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.animationUrl,
    required this.priceUsd,
    required this.isActive,
  });

  final String id;
  final String name;
  final String thumbnailUrl;
  final String? animationUrl;
  final double priceUsd;
  final bool isActive;

  GiftEntity copyWith({
    String? name,
    String? thumbnailUrl,
    String? animationUrl,
    double? priceUsd,
    bool? isActive,
  }) {
    return GiftEntity(
      id: id,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      priceUsd: priceUsd ?? this.priceUsd,
      isActive: isActive ?? this.isActive,
    );
  }
}
