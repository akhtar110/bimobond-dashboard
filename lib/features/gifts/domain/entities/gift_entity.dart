import '../enums/gift_size.dart';
import '../enums/gift_type.dart';

class GiftEntity {
  const GiftEntity({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.animationUrl,
    this.audioUrl,
    this.color,
    this.type = GiftType.image,
    this.tag,
    required this.priceCoins,
    required this.size,
    this.sortOrder = 0,
    required this.isActive,
    this.publishedAt,
    this.createdByName,
  });

  final String id;
  final String name;
  final String thumbnailUrl;
  final String? animationUrl;
  final String? audioUrl;
  final String? color;
  final GiftType type;

  /// Free-form shelf badge (max 50 chars), e.g. NEW / HOT / LIMITED.
  final String? tag;
  final double priceCoins;
  final GiftSize size;
  final int sortOrder;
  final bool isActive;
  final DateTime? publishedAt;

  /// Display name of the admin/user who created or published this gift.
  final String? createdByName;

  bool get isScheduled {
    final at = publishedAt;
    if (at == null) return false;
    return at.toUtc().isAfter(DateTime.now().toUtc());
  }

  bool get isPublishedNow {
    final at = publishedAt;
    if (at == null) return false;
    return !at.toUtc().isAfter(DateTime.now().toUtc());
  }

  GiftEntity copyWith({
    String? name,
    String? thumbnailUrl,
    String? animationUrl,
    String? audioUrl,
    String? color,
    GiftType? type,
    String? tag,
    double? priceCoins,
    GiftSize? size,
    int? sortOrder,
    bool? isActive,
    DateTime? publishedAt,
    String? createdByName,
    bool clearPublishedAt = false,
    bool clearCreatedByName = false,
    bool clearAnimationUrl = false,
    bool clearAudioUrl = false,
    bool clearColor = false,
    bool clearTag = false,
  }) {
    return GiftEntity(
      id: id,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      animationUrl:
          clearAnimationUrl ? null : (animationUrl ?? this.animationUrl),
      audioUrl: clearAudioUrl ? null : (audioUrl ?? this.audioUrl),
      color: clearColor ? null : (color ?? this.color),
      type: type ?? this.type,
      tag: clearTag ? null : (tag ?? this.tag),
      priceCoins: priceCoins ?? this.priceCoins,
      size: size ?? this.size,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      createdByName: clearCreatedByName
          ? null
          : (createdByName ?? this.createdByName),
    );
  }
}
