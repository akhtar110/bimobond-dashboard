import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';

class GiftModel extends GiftEntity {
  const GiftModel({
    required super.id,
    required super.name,
    required super.thumbnailUrl,
    super.animationUrl,
    super.audioUrl,
    super.color,
    super.type,
    super.tag,
    required super.priceCoins,
    required super.size,
    super.sortOrder,
    required super.isActive,
    super.publishedAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      thumbnailUrl: resolveMediaUrl(json['thumbnailUrl']?.toString()) ?? '',
      animationUrl: resolveMediaUrl(json['animationUrl']?.toString()),
      audioUrl: resolveMediaUrl(json['audioUrl']?.toString()),
      color: _normalizeColor(json['color']?.toString()),
      type: _resolveType(json),
      tag: _normalizeTag(json['tag']?.toString()),
      priceCoins: _d(json['priceCoins'] ?? json['priceUsd']),
      size: GiftSize.fromApi(json['size']?.toString()),
      sortOrder: _i(json['sortOrder']),
      isActive: json['isActive'] as bool? ?? true,
      publishedAt: _parseDate(json['publishedAt']),
    );
  }

  /// Prefer explicit `type`; if omitted, infer AUDIO when `audioUrl` is set.
  static GiftType _resolveType(Map<String, dynamic> json) {
    final raw = json['type']?.toString();
    if (raw != null && raw.trim().isNotEmpty) {
      return GiftType.fromApi(raw);
    }
    final audio = json['audioUrl']?.toString();
    if (audio != null && audio.trim().isNotEmpty) {
      return GiftType.audio;
    }
    return GiftType.image;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      if (animationUrl != null) 'animationUrl': animationUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (color != null) 'color': color,
      'type': type.apiValue,
      if (tag != null) 'tag': tag,
      'priceCoins': priceCoins,
      'size': size.apiValue,
      'sortOrder': sortOrder,
      'isActive': isActive,
      if (publishedAt != null)
        'publishedAt': publishedAt!.toUtc().toIso8601String(),
    };
  }

  static String? _normalizeTag(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    return value.length <= 50 ? value : value.substring(0, 50);
  }

  static String? _normalizeColor(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    return value.startsWith('#') ? value : '#$value';
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      final ms = v > 9999999999 ? v : v * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (v is num) {
      final n = v.toInt();
      final ms = n > 9999999999 ? n : n * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
