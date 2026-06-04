import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/gift_entity.dart';

class GiftModel extends GiftEntity {
  const GiftModel({
    required super.id,
    required super.name,
    required super.thumbnailUrl,
    super.animationUrl,
    required super.priceUsd,
    required super.isActive,
    super.createdAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      thumbnailUrl:
          resolveMediaUrl(json['thumbnailUrl']?.toString()) ?? '',
      animationUrl:
          resolveMediaUrl(json['animationUrl'] as String?),
      priceUsd: _d(json['priceUsd']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(
        json['publishedAt'] ?? json['published_at'] ?? json['createdAt'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
