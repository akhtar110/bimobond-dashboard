import 'package:equatable/equatable.dart';

import 'filter_settings_entities.dart';

class FiltersEffectsCountSummary extends Equatable {
  const FiltersEffectsCountSummary({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  @override
  List<Object?> get props => [total, active, inactive];
}

class FiltersEffectsOverviewEntity extends Equatable {
  const FiltersEffectsOverviewEntity({
    required this.filters,
    required this.filterCategories,
    required this.effects,
    required this.effectCategories,
    this.catalogVersion,
    this.catalogPublishedAt,
  });

  final FiltersEffectsCountSummary filters;
  final FiltersEffectsCountSummary filterCategories;
  final FiltersEffectsCountSummary effects;
  final FiltersEffectsCountSummary effectCategories;
  final String? catalogVersion;
  final DateTime? catalogPublishedAt;

  @override
  List<Object?> get props => [
    filters,
    filterCategories,
    effects,
    effectCategories,
    catalogVersion,
    catalogPublishedAt,
  ];
}

/// Free-form adjustment map from the admin API (`adjustments` / legacy).
class CameraFilterAdjustments extends Equatable {
  const CameraFilterAdjustments([this.values = const {}]);

  final Map<String, num> values;

  bool get isEmpty => values.isEmpty;

  CameraFilterAdjustments withValue(String key, num value) =>
      CameraFilterAdjustments({...values, key: value});

  CameraFilterAdjustments without(String key) {
    final next = Map<String, num>.from(values)..remove(key);
    return CameraFilterAdjustments(next);
  }

  Map<String, dynamic> toJson() =>
      values.map((key, value) => MapEntry(key, value));

  @override
  List<Object?> get props => [values];
}

class CameraFilterEntity extends Equatable {
  const CameraFilterEntity({
    required this.id,
    required this.slug,
    required this.label,
    this.customLabel,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.filterSettings = FilterSettingsEntity.empty,
    this.isOriginal = false,
    this.isBeautyDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.renderType = 'lut',
    this.colorMatrix = const [],
    this.lutUrl,
    this.lutAsset,
    this.adjustments = const CameraFilterAdjustments(),
  });

  final String id;
  final String slug;
  final String label;
  final String? customLabel;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final FilterSettingsEntity filterSettings;
  final bool isOriginal;
  final bool isBeautyDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String renderType;
  final List<double> colorMatrix;
  final String? lutUrl;
  final String? lutAsset;
  final CameraFilterAdjustments adjustments;

  CameraFilterAdjustments get effectiveAdjustments => adjustments;

  String get displayLabel {
    final custom = customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    return slug;
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    label,
    customLabel,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    filterSettings,
    isOriginal,
    isBeautyDefault,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
    renderType,
    colorMatrix,
    lutUrl,
    lutAsset,
    adjustments,
  ];
}

class CameraFilterCategoryEntity extends Equatable {
  const CameraFilterCategoryEntity({
    required this.id,
    required this.slug,
    required this.label,
    this.labelKey,
    required this.sortOrder,
    required this.isActive,
    this.filters = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String label;
  final String? labelKey;
  final int sortOrder;
  final bool isActive;
  final List<CameraFilterEntity> filters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get filtersCount => filters.length;

  String get displayLabel {
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    final key = labelKey?.trim();
    if (key != null && key.isNotEmpty) return key;
    return slug;
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    label,
    labelKey,
    sortOrder,
    isActive,
    filters,
    createdAt,
    updatedAt,
  ];
}

class CameraEffectStickerLayer extends Equatable {
  const CameraEffectStickerLayer({
    this.assetUrl,
    this.assetAsset,
    this.anchor = const {},
  });

  final String? assetUrl;
  final String? assetAsset;
  final Map<String, dynamic> anchor;

  bool get hasAsset {
    final url = assetUrl?.trim() ?? '';
    final asset = assetAsset?.trim() ?? '';
    return url.isNotEmpty || asset.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
    if (assetUrl != null && assetUrl!.trim().isNotEmpty)
      'assetUrl': assetUrl!.trim(),
    if (assetAsset != null && assetAsset!.trim().isNotEmpty)
      'assetAsset': assetAsset!.trim(),
    'anchor': anchor,
  };

  factory CameraEffectStickerLayer.fromJson(Map<String, dynamic> json) {
    final rawAnchor = json['anchor'];
    return CameraEffectStickerLayer(
      assetUrl: json['assetUrl']?.toString(),
      assetAsset: json['assetAsset']?.toString(),
      anchor: rawAnchor is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawAnchor)
          : const {},
    );
  }

  @override
  List<Object?> get props => [assetUrl, assetAsset, anchor];
}

class CameraEffectEntity extends Equatable {
  const CameraEffectEntity({
    required this.id,
    required this.slug,
    required this.renderType,
    required this.label,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.assetUrl,
    this.assetAsset,
    this.anchor = const {},
    this.stickers = const [],
    this.distortionPreset,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String renderType;
  final String label;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? assetUrl;
  final String? assetAsset;
  final Map<String, dynamic> anchor;
  final List<CameraEffectStickerLayer> stickers;
  final String? distortionPreset;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayLabel {
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    final key = labelKey?.trim();
    if (key != null && key.isNotEmpty) return key;
    return slug;
  }

  bool get hasAsset {
    final url = assetUrl?.trim() ?? '';
    final asset = assetAsset?.trim() ?? '';
    return url.isNotEmpty || asset.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    renderType,
    label,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    assetUrl,
    assetAsset,
    anchor,
    stickers,
    distortionPreset,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}

class CameraEffectCategoryEntity extends Equatable {
  const CameraEffectCategoryEntity({
    required this.id,
    required this.slug,
    required this.label,
    this.labelKey,
    required this.sortOrder,
    required this.isActive,
    this.effects = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String label;
  final String? labelKey;
  final int sortOrder;
  final bool isActive;
  final List<CameraEffectEntity> effects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get effectsCount => effects.length;

  String get displayLabel {
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    final key = labelKey?.trim();
    if (key != null && key.isNotEmpty) return key;
    return slug;
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    label,
    labelKey,
    sortOrder,
    isActive,
    effects,
    createdAt,
    updatedAt,
  ];
}

class CameraStudioCatalogEntity extends Equatable {
  const CameraStudioCatalogEntity({
    this.version,
    required this.filterCategories,
    required this.effectCategories,
  });

  final String? version;
  final List<CameraFilterCategoryEntity> filterCategories;
  final List<CameraEffectCategoryEntity> effectCategories;

  @override
  List<Object?> get props => [version, filterCategories, effectCategories];
}

class CatalogPublishResultEntity extends Equatable {
  const CatalogPublishResultEntity({
    required this.id,
    required this.version,
    required this.publishedAt,
    this.notes,
  });

  final String id;
  final String version;
  final DateTime publishedAt;
  final String? notes;

  @override
  List<Object?> get props => [id, version, publishedAt, notes];
}

class CatalogSeedResultEntity extends Equatable {
  const CatalogSeedResultEntity({required this.success, this.message});

  final bool success;
  final String? message;

  @override
  List<Object?> get props => [success, message];
}

/// Filter render types: responses lowercase, requests UPPERCASE.
abstract final class CameraFilterRenderTypeApi {
  static const matrix = 'matrix';
  static const lut = 'lut';

  static const values = [matrix, lut];

  static String fromResponse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'matrix':
        return matrix;
      case 'lut':
        return lut;
      default:
        return normalized.isEmpty ? matrix : normalized;
    }
  }

  static String toRequestJson(String value) {
    return switch (fromResponse(value)) {
      matrix => 'MATRIX',
      lut => 'LUT',
      _ => value.trim().toUpperCase().replaceAll('-', '_'),
    };
  }

  static String forAdminApi(String value) => toRequestJson(value);

  static bool matches(String a, String b) =>
      fromResponse(a) == fromResponse(b);

  static bool isMatrix(String value) => fromResponse(value) == matrix;

  static bool isLut(String value) => fromResponse(value) == lut;
}

/// Effect render types: responses lowercase, requests UPPERCASE.
abstract final class CameraEffectRenderTypeApi {
  static const none = 'none';
  static const sticker = 'sticker';
  static const composite = 'composite';
  static const distortion = 'distortion';

  static const values = [none, sticker, composite, distortion];

  static String fromResponse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'none':
        return none;
      case 'sticker':
        return sticker;
      case 'composite':
        return composite;
      case 'distortion':
        return distortion;
      default:
        return normalized.isEmpty ? none : normalized;
    }
  }

  static String toRequestJson(String value) {
    return switch (fromResponse(value)) {
      none => 'NONE',
      sticker => 'STICKER',
      composite => 'COMPOSITE',
      distortion => 'DISTORTION',
      _ => value.trim().toUpperCase().replaceAll('-', '_'),
    };
  }

  static String forAdminApi(String value) => toRequestJson(value);

  static bool matches(String a, String b) =>
      fromResponse(a) == fromResponse(b);

  static bool isNone(String value) => fromResponse(value) == none;

  static bool isSticker(String value) => fromResponse(value) == sticker;

  static bool isComposite(String value) => fromResponse(value) == composite;

  static bool isDistortion(String value) => fromResponse(value) == distortion;
}

abstract final class CameraDistortionPresetApi {
  static const bigEyes = 'big_eyes';
  static const bigLips = 'big_lips';
  static const longNose = 'long_nose';

  static const values = [bigEyes, bigLips, longNose];

  static String fromResponse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'big_eyes':
        return bigEyes;
      case 'big_lips':
        return bigLips;
      case 'long_nose':
        return longNose;
      default:
        return normalized;
    }
  }

  static String toRequestJson(String value) {
    return switch (fromResponse(value)) {
      bigEyes => 'BIG_EYES',
      bigLips => 'BIG_LIPS',
      longNose => 'LONG_NOSE',
      _ => value.trim().toUpperCase().replaceAll('-', '_'),
    };
  }

  static String forAdminApi(String value) => toRequestJson(value);

  static bool matches(String a, String b) =>
      fromResponse(a) == fromResponse(b);
}

/// Result of uploading a LUT source file (.cube or PNG) for a filter.
class FilterLutUploadResult extends Equatable {
  const FilterLutUploadResult({
    required this.lutUrl,
    this.lutAsset,
    this.sourceFilename,
  });

  final String lutUrl;
  final String? lutAsset;
  final String? sourceFilename;

  @override
  List<Object?> get props => [lutUrl, lutAsset, sourceFilename];
}

class CreateFilterRequest extends Equatable {
  const CreateFilterRequest({
    required this.slug,
    required this.label,
    this.customLabel,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.filterSettings,
    this.sortOrder = 0,
    this.isActive = true,
    this.renderType = 'lut',
    this.colorMatrix = const [],
    this.lutUrl,
    this.lutAsset,
    this.adjustments = const CameraFilterAdjustments(),
  });

  final String slug;
  final String label;
  final String? customLabel;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final FilterSettingsEntity? filterSettings;
  final int sortOrder;
  final bool isActive;
  final String renderType;
  final List<double> colorMatrix;
  final String? lutUrl;
  final String? lutAsset;
  final CameraFilterAdjustments adjustments;

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'label': label,
      if (customLabel != null && customLabel!.isNotEmpty) 'customLabel': customLabel,
      if (labelKey != null && labelKey!.isNotEmpty) 'labelKey': labelKey,
      if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
      if (previewColorHex != null && previewColorHex!.isNotEmpty)
        'previewColorHex': previewColorHex,
      if (filterSettings != null) 'filterSettings': filterSettings!.toJson(),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    slug,
    label,
    customLabel,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    filterSettings,
    sortOrder,
    isActive,
  ];
}

class UpdateFilterRequest extends Equatable {
  const UpdateFilterRequest({
    this.slug,
    this.label,
    this.customLabel,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.filterSettings,
    this.sortOrder,
    this.isActive,
    this.clearCustomLabel = false,
    this.clearLabelKey = false,
    this.clearEmoji = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
    this.renderType,
    this.colorMatrix,
    this.lutUrl,
    this.lutAsset,
    this.adjustments,
  });

  final String? slug;
  final String? label;
  final String? customLabel;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final FilterSettingsEntity? filterSettings;
  final int? sortOrder;
  final bool? isActive;
  final bool clearCustomLabel;
  final bool clearLabelKey;
  final bool clearEmoji;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;
  final String? renderType;
  final List<double>? colorMatrix;
  final String? lutUrl;
  final String? lutAsset;
  final CameraFilterAdjustments? adjustments;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (label != null) json['label'] = label;
    if (clearCustomLabel) {
      json['customLabel'] = null;
    } else if (customLabel != null) {
      json['customLabel'] = customLabel;
    }
    if (clearLabelKey) {
      json['labelKey'] = null;
    } else if (labelKey != null) {
      json['labelKey'] = labelKey;
    }
    if (clearEmoji) {
      json['emoji'] = null;
    } else if (emoji != null) {
      json['emoji'] = emoji;
    }
    if (clearThumbnailUrl) {
      json['thumbnailUrl'] = null;
    } else if (thumbnailUrl != null) {
      json['thumbnailUrl'] = thumbnailUrl;
    }
    if (clearPreviewColorHex) {
      json['previewColorHex'] = null;
    } else if (previewColorHex != null) {
      json['previewColorHex'] = previewColorHex;
    }
    if (filterSettings != null) {
      json['filterSettings'] = filterSettings!.toJson();
    }
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [
    slug,
    label,
    customLabel,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    filterSettings,
    sortOrder,
    isActive,
    clearCustomLabel,
    clearLabelKey,
    clearEmoji,
    clearThumbnailUrl,
    clearPreviewColorHex,
  ];
}

class CreateEffectRequest extends Equatable {
  const CreateEffectRequest({
    required this.slug,
    required this.renderType,
    required this.label,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.assetUrl,
    this.assetAsset,
    this.anchor = const {},
    this.stickers = const [],
    this.distortionPreset,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String slug;
  final String renderType;
  final String label;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? assetUrl;
  final String? assetAsset;
  final Map<String, dynamic> anchor;
  final List<CameraEffectStickerLayer> stickers;
  final String? distortionPreset;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'renderType': CameraEffectRenderTypeApi.toRequestJson(renderType),
      'label': label,
      if (labelKey != null && labelKey!.isNotEmpty) 'labelKey': labelKey,
      if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
      if (previewColorHex != null && previewColorHex!.isNotEmpty)
        'previewColorHex': previewColorHex,
      if (CameraEffectRenderTypeApi.isSticker(renderType)) ...{
        if (assetUrl != null && assetUrl!.isNotEmpty) 'assetUrl': assetUrl,
        if (assetAsset != null && assetAsset!.isNotEmpty)
          'assetAsset': assetAsset,
        'anchor': anchor,
      },
      if (CameraEffectRenderTypeApi.isComposite(renderType))
        'stickers': stickers.map((e) => e.toJson()).toList(),
      if (CameraEffectRenderTypeApi.isDistortion(renderType) &&
          distortionPreset != null &&
          distortionPreset!.isNotEmpty)
        'distortionPreset': CameraDistortionPresetApi.toRequestJson(
          distortionPreset!,
        ),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    slug,
    renderType,
    label,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    assetUrl,
    assetAsset,
    anchor,
    stickers,
    distortionPreset,
    sortOrder,
    isActive,
  ];
}

class UpdateEffectRequest extends Equatable {
  const UpdateEffectRequest({
    this.slug,
    this.renderType,
    this.label,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.assetUrl,
    this.assetAsset,
    this.anchor,
    this.stickers,
    this.distortionPreset,
    this.sortOrder,
    this.isActive,
    this.clearLabelKey = false,
    this.clearEmoji = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
    this.clearAssetUrl = false,
    this.clearAssetAsset = false,
    this.clearDistortionPreset = false,
  });

  final String? slug;
  final String? renderType;
  final String? label;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? assetUrl;
  final String? assetAsset;
  final Map<String, dynamic>? anchor;
  final List<CameraEffectStickerLayer>? stickers;
  final String? distortionPreset;
  final int? sortOrder;
  final bool? isActive;
  final bool clearLabelKey;
  final bool clearEmoji;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;
  final bool clearAssetUrl;
  final bool clearAssetAsset;
  final bool clearDistortionPreset;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (renderType != null) {
      json['renderType'] = CameraEffectRenderTypeApi.forAdminApi(renderType!);
    }
    if (label != null) json['label'] = label;
    if (clearLabelKey) {
      json['labelKey'] = null;
    } else if (labelKey != null) {
      json['labelKey'] = labelKey;
    }
    if (clearEmoji) {
      json['emoji'] = null;
    } else if (emoji != null) {
      json['emoji'] = emoji;
    }
    if (clearThumbnailUrl) {
      json['thumbnailUrl'] = null;
    } else if (thumbnailUrl != null) {
      json['thumbnailUrl'] = thumbnailUrl;
    }
    if (clearPreviewColorHex) {
      json['previewColorHex'] = null;
    } else if (previewColorHex != null) {
      json['previewColorHex'] = previewColorHex;
    }
    if (clearAssetUrl) {
      json['assetUrl'] = null;
    } else if (assetUrl != null) {
      json['assetUrl'] = assetUrl;
    }
    if (clearAssetAsset) {
      json['assetAsset'] = null;
    } else if (assetAsset != null) {
      json['assetAsset'] = assetAsset;
    }
    if (anchor != null) json['anchor'] = anchor;
    if (stickers != null) {
      json['stickers'] = stickers!.map((e) => e.toJson()).toList();
    }
    if (clearDistortionPreset) {
      json['distortionPreset'] = null;
    } else if (distortionPreset != null) {
      json['distortionPreset'] = CameraDistortionPresetApi.forAdminApi(
        distortionPreset!,
      );
    }
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [
    slug,
    renderType,
    label,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    assetUrl,
    assetAsset,
    anchor,
    stickers,
    distortionPreset,
    sortOrder,
    isActive,
    clearLabelKey,
    clearEmoji,
    clearThumbnailUrl,
    clearPreviewColorHex,
    clearAssetUrl,
    clearAssetAsset,
    clearDistortionPreset,
  ];
}

class CreateCategoryRequest extends Equatable {
  const CreateCategoryRequest({
    required this.slug,
    required this.label,
    this.labelKey,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String slug;
  final String label;
  final String? labelKey;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'label': label,
    if (labelKey != null && labelKey!.isNotEmpty) 'labelKey': labelKey,
    'sortOrder': sortOrder,
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [slug, label, labelKey, sortOrder, isActive];
}

class UpdateCategoryRequest extends Equatable {
  const UpdateCategoryRequest({
    this.slug,
    this.label,
    this.labelKey,
    this.sortOrder,
    this.isActive,
    this.clearLabelKey = false,
  });

  final String? slug;
  final String? label;
  final String? labelKey;
  final int? sortOrder;
  final bool? isActive;
  final bool clearLabelKey;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (label != null) json['label'] = label;
    if (clearLabelKey) {
      json['labelKey'] = null;
    } else if (labelKey != null) {
      json['labelKey'] = labelKey;
    }
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [
    slug,
    label,
    labelKey,
    sortOrder,
    isActive,
    clearLabelKey,
  ];
}

class CategoryReorderItem extends Equatable {
  const CategoryReorderItem({required this.id, required this.sortOrder});

  final String id;
  final int sortOrder;

  Map<String, dynamic> toJson() => {'id': id, 'sortOrder': sortOrder};

  @override
  List<Object?> get props => [id, sortOrder];
}

class FilterAssignmentItem extends Equatable {
  const FilterAssignmentItem({required this.filterId, required this.sortOrder});

  final String filterId;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'filterId': filterId,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [filterId, sortOrder];
}

class EffectAssignmentItem extends Equatable {
  const EffectAssignmentItem({required this.effectId, required this.sortOrder});

  final String effectId;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'effectId': effectId,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [effectId, sortOrder];
}

class PublishCatalogRequest extends Equatable {
  const PublishCatalogRequest({required this.version, this.notes});

  final String version;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'version': version,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };

  @override
  List<Object?> get props => [version, notes];
}

enum FiltersEffectsTab {
  filters,
  filterCategories,
  effects,
  effectCategories,
  arOverlays,
  catalog,
}

enum FiltersEffectsStatusFilter { all, active, inactive }

class FiltersEffectsPaginationMeta extends Equatable {
  const FiltersEffectsPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

class PaginatedCameraFiltersEntity extends Equatable {
  const PaginatedCameraFiltersEntity({
    required this.data,
    required this.meta,
  });

  final List<CameraFilterEntity> data;
  final FiltersEffectsPaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}

class PaginatedCameraEffectsEntity extends Equatable {
  const PaginatedCameraEffectsEntity({
    required this.data,
    required this.meta,
  });

  final List<CameraEffectEntity> data;
  final FiltersEffectsPaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}

class BulkUpdateCameraFilterItem extends Equatable {
  const BulkUpdateCameraFilterItem({
    required this.id,
    this.label,
    this.customLabel,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.filterSettings,
    this.sortOrder,
    this.isActive,
  });

  final String id;
  final String? label;
  final String? customLabel;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final FilterSettingsEntity? filterSettings;
  final int? sortOrder;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'id': id};
    if (label != null) json['label'] = label;
    if (customLabel != null) json['customLabel'] = customLabel;
    if (labelKey != null) json['labelKey'] = labelKey;
    if (emoji != null) json['emoji'] = emoji;
    if (thumbnailUrl != null) json['thumbnailUrl'] = thumbnailUrl;
    if (previewColorHex != null) json['previewColorHex'] = previewColorHex;
    if (filterSettings != null) json['filterSettings'] = filterSettings!.toJson();
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [
    id,
    label,
    customLabel,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    filterSettings,
    sortOrder,
    isActive,
  ];
}

class BulkUpdateCameraFiltersRequest extends Equatable {
  const BulkUpdateCameraFiltersRequest({required this.items});

  final List<BulkUpdateCameraFilterItem> items;

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [items];
}

enum FiltersEffectsBulkAction { activate, deactivate, delete }

class BulkCameraFiltersRequest extends Equatable {
  const BulkCameraFiltersRequest({
    required this.filterIds,
    required this.action,
  });

  final List<String> filterIds;
  final FiltersEffectsBulkAction action;

  Map<String, dynamic> toJson() => {
    'filterIds': filterIds,
    'action': switch (action) {
      FiltersEffectsBulkAction.activate => 'ACTIVATE',
      FiltersEffectsBulkAction.deactivate => 'DEACTIVATE',
      FiltersEffectsBulkAction.delete => 'DELETE',
    },
  };

  @override
  List<Object?> get props => [filterIds, action];
}

class BulkCameraEffectsRequest extends Equatable {
  const BulkCameraEffectsRequest({
    required this.effectIds,
    required this.action,
  });

  final List<String> effectIds;
  final FiltersEffectsBulkAction action;

  Map<String, dynamic> toJson() => {
    'effectIds': effectIds,
    'action': switch (action) {
      FiltersEffectsBulkAction.activate => 'ACTIVATE',
      FiltersEffectsBulkAction.deactivate => 'DEACTIVATE',
      FiltersEffectsBulkAction.delete => 'DELETE',
    },
  };

  @override
  List<Object?> get props => [effectIds, action];
}

class BulkCameraFiltersResult extends Equatable {
  const BulkCameraFiltersResult({
    required this.action,
    required this.successCount,
    required this.notFoundCount,
    required this.filterIds,
    required this.notFoundIds,
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> filterIds;
  final List<String> notFoundIds;

  @override
  List<Object?> get props => [
    action,
    successCount,
    notFoundCount,
    filterIds,
    notFoundIds,
  ];
}

class BulkCameraEffectsResult extends Equatable {
  const BulkCameraEffectsResult({
    required this.action,
    required this.successCount,
    required this.notFoundCount,
    required this.effectIds,
    required this.notFoundIds,
  });

  final String action;
  final int successCount;
  final int notFoundCount;
  final List<String> effectIds;
  final List<String> notFoundIds;

  @override
  List<Object?> get props => [
    action,
    successCount,
    notFoundCount,
    effectIds,
    notFoundIds,
  ];
}

class FiltersEffectsListQuery extends Equatable {
  const FiltersEffectsListQuery({
    this.search = '',
    this.status = FiltersEffectsStatusFilter.active,
    this.renderType,
    this.category,
    this.categoryId,
    this.page = 1,
    this.pageSize = 25,
  });

  final String search;
  final FiltersEffectsStatusFilter status;
  final String? renderType;
  final String? category;
  final String? categoryId;
  final int page;
  final int pageSize;

  /// Maps UI query state to admin list API query params.
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': pageSize.clamp(1, 100),
    };
    final trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) params['search'] = trimmedSearch;
    if (status == FiltersEffectsStatusFilter.active) {
      params['isActive'] = true;
    } else if (status == FiltersEffectsStatusFilter.inactive) {
      params['isActive'] = false;
    }
    if (renderType != null && renderType!.trim().isNotEmpty) {
      params['renderType'] = CameraFilterRenderTypeApi.toRequestJson(
        renderType!,
      );
    }
    if (category != null && category!.trim().isNotEmpty) {
      params['category'] = category!.trim();
    }
    if (categoryId != null && categoryId!.trim().isNotEmpty) {
      params['categoryId'] = categoryId!.trim();
    }
    return params;
  }

  /// Effect lists use the same params; render types differ per resource.
  Map<String, dynamic> toEffectQueryParameters() {
    final params = toQueryParameters();
    if (renderType != null && renderType!.trim().isNotEmpty) {
      params['renderType'] = CameraEffectRenderTypeApi.toRequestJson(
        renderType!,
      );
    }
    return params;
  }

  FiltersEffectsListQuery copyWith({
    String? search,
    FiltersEffectsStatusFilter? status,
    String? renderType,
    String? category,
    String? categoryId,
    int? page,
    int? pageSize,
    bool clearRenderType = false,
    bool clearCategory = false,
    bool clearCategoryId = false,
  }) {
    return FiltersEffectsListQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      renderType: clearRenderType ? null : (renderType ?? this.renderType),
      category: clearCategory ? null : (category ?? this.category),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
    search,
    status,
    renderType,
    category,
    categoryId,
    page,
    pageSize,
  ];
}
