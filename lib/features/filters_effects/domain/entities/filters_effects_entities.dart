import 'package:equatable/equatable.dart';

import 'effect_placement_entities.dart';
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
    required this.catalogVersion,
    this.catalogPublishedAt,
  });

  final FiltersEffectsCountSummary filters;
  final FiltersEffectsCountSummary filterCategories;
  final FiltersEffectsCountSummary effects;
  final FiltersEffectsCountSummary effectCategories;
  final String catalogVersion;
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

class CameraFilterEntity extends Equatable {
  const CameraFilterEntity({
    required this.id,
    required this.slug,
    required this.engineType,
    required this.engineKey,
    this.labelKey,
    this.customLabel,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isOriginal = false,
    this.isBeautyDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.filterSettings = const FilterSettingsEntity({}),
    this.colorMatrix = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String engineType;
  final String engineKey;
  final String? labelKey;
  final String? customLabel;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool isOriginal;
  final bool isBeautyDefault;
  final bool isActive;
  final int sortOrder;
  final FilterSettingsEntity filterSettings;
  final List<double> colorMatrix;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayLabel => customLabel ?? labelKey ?? engineKey;

  @override
  List<Object?> get props => [
        id,
        slug,
        engineType,
        engineKey,
        labelKey,
        customLabel,
        thumbnailUrl,
        previewColorHex,
        isOriginal,
        isBeautyDefault,
        isActive,
        sortOrder,
        filterSettings,
        colorMatrix,
        createdAt,
        updatedAt,
      ];
}

class CameraFilterCategoryEntity extends Equatable {
  const CameraFilterCategoryEntity({
    required this.id,
    required this.slug,
    required this.labelKey,
    required this.sortOrder,
    required this.isActive,
    this.filters = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String labelKey;
  final int sortOrder;
  final bool isActive;
  final List<CameraFilterEntity> filters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get filtersCount => filters.length;

  @override
  List<Object?> get props => [
        id,
        slug,
        labelKey,
        sortOrder,
        isActive,
        filters,
        createdAt,
        updatedAt,
      ];
}

class CameraEffectEntity extends Equatable {
  const CameraEffectEntity({
    required this.id,
    required this.slug,
    required this.effectType,
    this.emoji,
    this.assetUrl,
    this.previewColorHex,
    required this.labelKey,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.anchorType,
    this.anchorLandmarks = const [],
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.fallbackAnchorType,
    this.fallbackOffsetY,
    this.fallbackScaleFactor,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String effectType;
  final String? emoji;
  final String? assetUrl;
  final String? previewColorHex;
  final String labelKey;
  final bool requiresFaceDetection;
  final bool isScreenEffect;
  final bool isActive;
  final int sortOrder;
  final String? anchorType;
  final List<String> anchorLandmarks;
  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final String? fallbackAnchorType;
  final double? fallbackOffsetY;
  final double? fallbackScaleFactor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EffectPlacementSettingsEntity get placement => EffectPlacementSettingsEntity(
        anchorType: anchorType,
        anchorLandmarks: anchorLandmarks,
        scaleFactor: scaleFactor,
        offsetX: offsetX,
        offsetY: offsetY,
        landmarkSize: landmarkSize,
        fallbackAnchorType: fallbackAnchorType,
        fallbackOffsetY: fallbackOffsetY,
        fallbackScaleFactor: fallbackScaleFactor,
      );

  @override
  List<Object?> get props => [
        id,
        slug,
        effectType,
        emoji,
        assetUrl,
        previewColorHex,
        labelKey,
        requiresFaceDetection,
        isScreenEffect,
        isActive,
        sortOrder,
        anchorType,
        anchorLandmarks,
        scaleFactor,
        offsetX,
        offsetY,
        landmarkSize,
        fallbackAnchorType,
        fallbackOffsetY,
        fallbackScaleFactor,
        createdAt,
        updatedAt,
      ];
}

class CameraEffectCategoryEntity extends Equatable {
  const CameraEffectCategoryEntity({
    required this.id,
    required this.slug,
    required this.labelKey,
    required this.sortOrder,
    required this.isActive,
    this.effects = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String labelKey;
  final int sortOrder;
  final bool isActive;
  final List<CameraEffectEntity> effects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get effectsCount => effects.length;

  @override
  List<Object?> get props => [
        id,
        slug,
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
    required this.version,
    required this.filterCategories,
    required this.effectCategories,
  });

  final String version;
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

class CreateFilterRequest extends Equatable {
  const CreateFilterRequest({
    required this.slug,
    required this.engineKey,
    this.engineType = 'CAMERAAWESOME',
    this.labelKey,
    this.customLabel,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isOriginal = false,
    this.isBeautyDefault = false,
    this.sortOrder = 0,
    this.isActive = true,
    this.filterSettings = const FilterSettingsEntity({}),
  });

  final String slug;
  final String engineKey;
  final String engineType;
  final String? labelKey;
  final String? customLabel;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool isOriginal;
  final bool isBeautyDefault;
  final int sortOrder;
  final bool isActive;
  final FilterSettingsEntity filterSettings;

  Map<String, dynamic> toJson({FilterSettingsSchemaEntity? schema}) => {
        'slug': slug,
        'engineKey': engineKey,
        'engineType': CameraFilterEngineTypeApi.forAdminApi(engineType),
        if (labelKey != null && labelKey!.isNotEmpty) 'labelKey': labelKey,
        if (customLabel != null && customLabel!.isNotEmpty)
          'customLabel': customLabel,
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (previewColorHex != null && previewColorHex!.isNotEmpty)
          'previewColorHex': previewColorHex,
        'isOriginal': isOriginal,
        'isBeautyDefault': isBeautyDefault,
        'sortOrder': sortOrder,
        'isActive': isActive,
        if (schema != null)
          'filterSettings': filterSettings.toFullApiJson(schema),
      };

  @override
  List<Object?> get props => [
        slug,
        engineKey,
        engineType,
        labelKey,
        customLabel,
        thumbnailUrl,
        previewColorHex,
        isOriginal,
        isBeautyDefault,
        sortOrder,
        isActive,
        filterSettings,
      ];
}

class UpdateFilterRequest extends Equatable {
  const UpdateFilterRequest({
    this.slug,
    this.engineKey,
    this.engineType,
    this.labelKey,
    this.customLabel,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isOriginal,
    this.isBeautyDefault,
    this.sortOrder,
    this.isActive,
    this.filterSettings,
    this.clearLabelKey = false,
    this.clearCustomLabel = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
    this.clearFilterSettings = false,
  });

  final String? slug;
  final String? engineKey;
  final String? engineType;
  final String? labelKey;
  final String? customLabel;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool? isOriginal;
  final bool? isBeautyDefault;
  final int? sortOrder;
  final bool? isActive;
  final FilterSettingsEntity? filterSettings;
  final bool clearLabelKey;
  final bool clearCustomLabel;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;
  final bool clearFilterSettings;

  Map<String, dynamic> toJson({FilterSettingsSchemaEntity? schema}) {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (engineKey != null) json['engineKey'] = engineKey;
    if (engineType != null) {
      json['engineType'] = CameraFilterEngineTypeApi.forAdminApi(engineType!);
    }
    if (clearLabelKey) {
      json['labelKey'] = null;
    } else if (labelKey != null) {
      json['labelKey'] = labelKey;
    }
    if (clearCustomLabel) {
      json['customLabel'] = null;
    } else if (customLabel != null) {
      json['customLabel'] = customLabel;
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
    if (isOriginal != null) json['isOriginal'] = isOriginal;
    if (isBeautyDefault != null) json['isBeautyDefault'] = isBeautyDefault;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    if (clearFilterSettings) {
      json['filterSettings'] = {};
    } else if (filterSettings != null && schema != null) {
      // Full snapshot so beauty/client-only keys reset cleanly on PATCH.
      json['filterSettings'] = filterSettings!.toFullApiJson(schema);
    }
    return json;
  }

  @override
  List<Object?> get props => [
        slug,
        engineKey,
        engineType,
        labelKey,
        customLabel,
        thumbnailUrl,
        previewColorHex,
        isOriginal,
        isBeautyDefault,
        sortOrder,
        isActive,
        filterSettings,
        clearLabelKey,
        clearCustomLabel,
        clearThumbnailUrl,
        clearPreviewColorHex,
        clearFilterSettings,
      ];
}

/// Admin write enum (`CAMERAAWESOME`) vs catalog read value (`camerawesome`).
abstract final class CameraFilterEngineTypeApi {
  static const camerawesome = 'CAMERAAWESOME';

  static String forAdminApi(String value) {
    final normalized = value.trim().toUpperCase().replaceAll('-', '_');
    switch (normalized) {
      case 'CAMERAAWESOME':
      case 'CAMERAWESOME':
        return camerawesome;
      default:
        if (value.trim().toLowerCase() == 'camerawesome') return camerawesome;
        return normalized.isEmpty ? camerawesome : normalized;
    }
  }
}

/// Admin API effect types (`FACE_AR`, `SCREEN_OVERLAY`) vs catalog snake_case.
abstract final class CameraEffectTypeApi {
  static const faceAr = 'FACE_AR';
  static const screenOverlay = 'SCREEN_OVERLAY';

  static const values = [faceAr, screenOverlay];

  static String normalize(String value) {
    final normalized = value.trim().toUpperCase().replaceAll('-', '_');
    switch (normalized) {
      case 'FACE_AR':
      case 'FACEAR':
        return faceAr;
      case 'SCREEN_OVERLAY':
      case 'SCREENOVERLAY':
      case 'OVERLAY':
        return screenOverlay;
      default:
        final lower = value.trim().toLowerCase();
        if (lower == 'face_ar') return faceAr;
        if (lower == 'screen_overlay') return screenOverlay;
        return normalized.isEmpty ? faceAr : normalized;
    }
  }

  static bool isScreenOverlay(String value) =>
      normalize(value) == screenOverlay;

  /// Keeps effect flags aligned with the selected admin enum.
  static ({bool requiresFaceDetection, bool isScreenEffect}) flagsForType(
    String value, {
    bool requiresFaceDetection = false,
  }) {
    if (isScreenOverlay(value)) {
      return (requiresFaceDetection: false, isScreenEffect: true);
    }
    return (requiresFaceDetection: requiresFaceDetection, isScreenEffect: false);
  }
}

class CreateEffectRequest extends Equatable {
  const CreateEffectRequest({
    required this.slug,
    required this.effectType,
    this.emoji,
    this.assetUrl,
    required this.previewColorHex,
    required this.labelKey,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
    this.sortOrder = 0,
    this.isActive = true,
    this.placement = EffectPlacementSettingsEntity.empty,
  });

  final String slug;
  final String effectType;
  final String? emoji;
  final String? assetUrl;
  final String previewColorHex;
  final String labelKey;
  final bool requiresFaceDetection;
  final bool isScreenEffect;
  final int sortOrder;
  final bool isActive;
  final EffectPlacementSettingsEntity placement;

  Map<String, dynamic> toJson() {
    final includePlacement = !isScreenEffect && requiresFaceDetection;
    return {
      'slug': slug,
      'effectType': CameraEffectTypeApi.normalize(effectType),
      if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
      if (assetUrl != null && assetUrl!.isNotEmpty) 'assetUrl': assetUrl,
      'previewColorHex': previewColorHex,
      'labelKey': labelKey,
      'requiresFaceDetection': requiresFaceDetection,
      'isScreenEffect': isScreenEffect,
      'sortOrder': sortOrder,
      'isActive': isActive,
      ...placement.toCreateJson(
        includePlacement: includePlacement || isScreenEffect,
      ),
      if (isScreenEffect)
        'anchorType': CameraEffectAnchorTypeApi.forApi(
          CameraEffectAnchorTypeApi.screen,
        ),
    };
  }

  @override
  List<Object?> get props => [
        slug,
        effectType,
        emoji,
        assetUrl,
        previewColorHex,
        labelKey,
        requiresFaceDetection,
        isScreenEffect,
        sortOrder,
        isActive,
        placement,
      ];
}

class UpdateEffectRequest extends Equatable {
  const UpdateEffectRequest({
    this.slug,
    this.effectType,
    this.emoji,
    this.assetUrl,
    this.previewColorHex,
    this.labelKey,
    this.requiresFaceDetection,
    this.isScreenEffect,
    this.sortOrder,
    this.isActive,
    this.placement,
    this.clearEmoji = false,
    this.clearAssetUrl = false,
    this.clearAnchorLandmarks = false,
  });

  final String? slug;
  final String? effectType;
  final String? emoji;
  final String? assetUrl;
  final String? previewColorHex;
  final String? labelKey;
  final bool? requiresFaceDetection;
  final bool? isScreenEffect;
  final int? sortOrder;
  final bool? isActive;
  final EffectPlacementSettingsEntity? placement;
  final bool clearEmoji;
  final bool clearAssetUrl;
  final bool clearAnchorLandmarks;

  Map<String, dynamic> toJson({EffectPlacementSettingsEntity? baselinePlacement}) {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (effectType != null) {
      json['effectType'] = CameraEffectTypeApi.normalize(effectType!);
    }
    if (clearEmoji) {
      json['emoji'] = null;
    } else if (emoji != null) {
      json['emoji'] = emoji;
    }
    if (clearAssetUrl) {
      json['assetUrl'] = null;
    } else if (assetUrl != null) {
      json['assetUrl'] = assetUrl;
    }
    if (previewColorHex != null) json['previewColorHex'] = previewColorHex;
    if (labelKey != null) json['labelKey'] = labelKey;
    if (requiresFaceDetection != null) {
      json['requiresFaceDetection'] = requiresFaceDetection;
    }
    if (isScreenEffect != null) json['isScreenEffect'] = isScreenEffect;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    if (placement != null) {
      json.addAll(
        placement!.toUpdateJson(
          baseline: baselinePlacement,
          clearAnchorLandmarks: clearAnchorLandmarks,
        ),
      );
    }
    return json;
  }

  @override
  List<Object?> get props => [
        slug,
        effectType,
        emoji,
        assetUrl,
        previewColorHex,
        labelKey,
        requiresFaceDetection,
        isScreenEffect,
        sortOrder,
        isActive,
        placement,
        clearEmoji,
        clearAssetUrl,
        clearAnchorLandmarks,
      ];
}

class CreateCategoryRequest extends Equatable {
  const CreateCategoryRequest({
    required this.slug,
    required this.labelKey,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String slug;
  final String labelKey;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'labelKey': labelKey,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [slug, labelKey, sortOrder, isActive];
}

class UpdateCategoryRequest extends Equatable {
  const UpdateCategoryRequest({
    this.slug,
    this.labelKey,
    this.sortOrder,
    this.isActive,
  });

  final String? slug;
  final String? labelKey;
  final int? sortOrder;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (labelKey != null) json['labelKey'] = labelKey;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [slug, labelKey, sortOrder, isActive];
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
  catalog,
}

enum FiltersEffectsStatusFilter { all, active, inactive }

class FiltersEffectsListQuery extends Equatable {
  const FiltersEffectsListQuery({
    this.search = '',
    this.status = FiltersEffectsStatusFilter.all,
    this.engineKey,
    this.page = 1,
    this.pageSize = 25,
  });

  final String search;
  final FiltersEffectsStatusFilter status;
  final String? engineKey;
  final int page;
  final int pageSize;

  FiltersEffectsListQuery copyWith({
    String? search,
    FiltersEffectsStatusFilter? status,
    String? engineKey,
    int? page,
    int? pageSize,
    bool clearEngineKey = false,
  }) {
    return FiltersEffectsListQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      engineKey: clearEngineKey ? null : (engineKey ?? this.engineKey),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [search, status, engineKey, page, pageSize];
}
