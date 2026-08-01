import 'dart:typed_data';

import '../../domain/entities/ar_overlay_entities.dart';

/// Single AR Overlay Model with JSON serialization / deserialization.
class ArOverlayModel extends ArOverlayEntity {
  const ArOverlayModel({
    required super.id,
    required super.label,
    super.sortOrder = 0,
    required super.lottieUrl,
    super.emoji,
    super.thumbnailUrl,
    super.previewColorHex,
    super.isActive = true,
  });

  factory ArOverlayModel.fromJson(Map<String, dynamic> json) {
    final rawSort = json['sortOrder'];
    final int sortOrder = rawSort is num
        ? rawSort.toInt()
        : int.tryParse(rawSort?.toString() ?? '') ?? 0;

    return ArOverlayModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      sortOrder: sortOrder,
      lottieUrl: json['lottieUrl']?.toString() ?? '',
      emoji: json['emoji']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      previewColorHex: json['previewColorHex']?.toString(),
      isActive: _readBool(json['isActive'] ?? json['active'], fallback: true),
    );
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'sortOrder': sortOrder,
      'lottieUrl': lottieUrl,
      if (emoji != null) 'emoji': emoji,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (previewColorHex != null) 'previewColorHex': previewColorHex,
      'isActive': isActive,
    };
  }
}

/// Metadata model for admin list response pagination.
class ArOverlayMetaModel extends ArOverlayMetaEntity {
  const ArOverlayMetaModel({
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
  });

  factory ArOverlayMetaModel.fromJson(Map<String, dynamic> json) {
    num toNum(dynamic val, num fallback) => val is num ? val : num.tryParse(val?.toString() ?? '') ?? fallback;

    return ArOverlayMetaModel(
      total: toNum(json['total'], 0).toInt(),
      page: toNum(json['page'], 1).toInt(),
      limit: toNum(json['limit'], 20).toInt(),
      totalPages: toNum(json['totalPages'], 1).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}

/// Category model for the public AR Overlays catalog response.
class ArOverlayCategoryModel extends ArOverlayCategoryEntity {
  const ArOverlayCategoryModel({
    required super.id,
    required super.label,
    super.sortOrder = 0,
    super.overlays = const [],
  });

  factory ArOverlayCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSort = json['sortOrder'];
    final int sortOrder = rawSort is num ? rawSort.toInt() : int.tryParse(rawSort?.toString() ?? '') ?? 0;
    final rawList = json['overlays'] as List<dynamic>? ?? const [];

    return ArOverlayCategoryModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      sortOrder: sortOrder,
      overlays: rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => ArOverlayModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'sortOrder': sortOrder,
      'overlays': overlays.map((e) {
        if (e is ArOverlayModel) return e.toJson();
        return {
          'id': e.id,
          'label': e.label,
          'sortOrder': e.sortOrder,
          'lottieUrl': e.lottieUrl,
          if (e.emoji != null) 'emoji': e.emoji,
          if (e.thumbnailUrl != null) 'thumbnailUrl': e.thumbnailUrl,
          if (e.previewColorHex != null) 'previewColorHex': e.previewColorHex,
          'isActive': e.isActive,
        };
      }).toList(),
    };
  }
}

/// Public Catalog response model.
class ArOverlayCatalogResponseModel extends ArOverlayCatalogResponseEntity {
  const ArOverlayCatalogResponseModel({
    required super.version,
    super.overlayCategories = const [],
  });

  factory ArOverlayCatalogResponseModel.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['overlayCategories'] as List<dynamic>? ?? const [];
    return ArOverlayCatalogResponseModel(
      version: json['version']?.toString() ?? '',
      overlayCategories: rawCategories
          .whereType<Map<String, dynamic>>()
          .map((item) => ArOverlayCategoryModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'overlayCategories': overlayCategories.map((c) {
        if (c is ArOverlayCategoryModel) return c.toJson();
        return {
          'id': c.id,
          'label': c.label,
          'sortOrder': c.sortOrder,
          'overlays': c.overlays.map((e) => e.id).toList(),
        };
      }).toList(),
    };
  }
}

/// Admin paginated list response model.
class ArOverlayListResponseModel extends ArOverlayListResponseEntity {
  const ArOverlayListResponseModel({
    required super.version,
    super.data = const [],
    required super.meta,
  });

  factory ArOverlayListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? const [];
    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};

    return ArOverlayListResponseModel(
      version: json['version']?.toString() ?? '',
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => ArOverlayModel.fromJson(item))
          .toList(),
      meta: ArOverlayMetaModel.fromJson(metaJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'data': data.map((e) {
        if (e is ArOverlayModel) return e.toJson();
        return {
          'id': e.id,
          'label': e.label,
          'sortOrder': e.sortOrder,
          'lottieUrl': e.lottieUrl,
          if (e.emoji != null) 'emoji': e.emoji,
          if (e.thumbnailUrl != null) 'thumbnailUrl': e.thumbnailUrl,
          if (e.previewColorHex != null) 'previewColorHex': e.previewColorHex,
          'isActive': e.isActive,
        };
      }).toList(),
      'meta': meta is ArOverlayMetaModel
          ? (meta as ArOverlayMetaModel).toJson()
          : {
              'total': meta.total,
              'page': meta.page,
              'limit': meta.limit,
              'totalPages': meta.totalPages,
            },
    };
  }
}

/// DTO used when creating a new AR Overlay (`POST /camera-studio/ar-overlays/admin`).
class CreateArOverlayData {
  const CreateArOverlayData({
    required this.id,
    required this.label,
    this.sortOrder = 0,
    required this.lottieUrl,
    this.lottieBytes,
    this.lottieFilename,
    this.emoji,
    this.thumbnailUrl,
    this.thumbnailBytes,
    this.thumbnailFilename,
    this.previewColorHex,
  });

  final String id;
  final String label;
  final int sortOrder;
  /// CDN /uploads URL for the Lottie JSON (never base64 / raw JSON).
  final String lottieUrl;
  /// Optional raw bytes — uploaded to CDN before create if still present.
  final Uint8List? lottieBytes;
  final String? lottieFilename;
  final String? emoji;
  /// CDN /uploads URL for the thumbnail image (never base64).
  final String? thumbnailUrl;
  /// Raw bytes of the picked image file, used for multipart upload.
  final Uint8List? thumbnailBytes;
  final String? thumbnailFilename;
  final String? previewColorHex;

  /// Returns a copy with resolved (CDN) URLs replacing any data URLs.
  CreateArOverlayData withResolvedUrls({
    String? lottieUrl,
    String? thumbnailUrl,
  }) {
    return CreateArOverlayData(
      id: id,
      label: label,
      sortOrder: sortOrder,
      lottieUrl: lottieUrl ?? this.lottieUrl,
      emoji: emoji,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewColorHex: previewColorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.trim(),
      'label': label.trim(),
      'sortOrder': sortOrder,
      'lottieUrl': lottieUrl.trim(),
      if (emoji != null && emoji!.trim().isNotEmpty) 'emoji': emoji!.trim(),
      if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty)
        'thumbnailUrl': thumbnailUrl!.trim(),
      if (previewColorHex != null && previewColorHex!.trim().isNotEmpty)
        'previewColorHex': previewColorHex!.trim(),
    };
  }
}

/// DTO used when updating an existing AR Overlay (`PATCH /camera-studio/ar-overlays/admin/:id`).
class UpdateArOverlayData {
  const UpdateArOverlayData({
    this.id,
    this.label,
    this.sortOrder,
    this.lottieUrl,
    this.lottieBytes,
    this.lottieFilename,
    this.emoji,
    this.thumbnailUrl,
    this.thumbnailBytes,
    this.thumbnailFilename,
    this.previewColorHex,
  });

  final String? id;
  final String? label;
  final int? sortOrder;
  /// CDN /uploads URL for the Lottie JSON (never base64 / raw JSON).
  final String? lottieUrl;
  /// Optional raw bytes — uploaded to CDN before update if still present.
  final Uint8List? lottieBytes;
  final String? lottieFilename;
  final String? emoji;
  /// CDN /uploads URL for the thumbnail image (never base64).
  final String? thumbnailUrl;
  /// Raw bytes of the picked image file, used for multipart upload.
  final Uint8List? thumbnailBytes;
  final String? thumbnailFilename;
  final String? previewColorHex;

  /// Returns a copy with resolved (CDN) URLs replacing any data URLs.
  UpdateArOverlayData withResolvedUrls({
    String? lottieUrl,
    String? thumbnailUrl,
  }) {
    return UpdateArOverlayData(
      id: id,
      label: label,
      sortOrder: sortOrder,
      lottieUrl: lottieUrl ?? this.lottieUrl,
      emoji: emoji,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewColorHex: previewColorHex,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (label != null) map['label'] = label!.trim();
    if (sortOrder != null) map['sortOrder'] = sortOrder;
    if (lottieUrl != null) map['lottieUrl'] = lottieUrl!.trim();
    if (emoji != null) map['emoji'] = emoji!.trim();
    if (thumbnailUrl != null) map['thumbnailUrl'] = thumbnailUrl!.trim();
    if (previewColorHex != null) map['previewColorHex'] = previewColorHex!.trim();
    return map;
  }
}
