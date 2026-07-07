import 'package:equatable/equatable.dart';

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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'engineKey': engineKey,
        'engineType': engineType,
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
    this.clearLabelKey = false,
    this.clearCustomLabel = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
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
  final bool clearLabelKey;
  final bool clearCustomLabel;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (engineKey != null) json['engineKey'] = engineKey;
    if (engineType != null) json['engineType'] = engineType;
    if (labelKey != null) json['labelKey'] = labelKey;
    if (customLabel != null) json['customLabel'] = customLabel;
    if (thumbnailUrl != null) json['thumbnailUrl'] = thumbnailUrl;
    if (previewColorHex != null) json['previewColorHex'] = previewColorHex;
    if (isOriginal != null) json['isOriginal'] = isOriginal;
    if (isBeautyDefault != null) json['isBeautyDefault'] = isBeautyDefault;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
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
      ];
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

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'effectType': effectType,
        if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
        if (assetUrl != null && assetUrl!.isNotEmpty) 'assetUrl': assetUrl,
        'previewColorHex': previewColorHex,
        'labelKey': labelKey,
        'requiresFaceDetection': requiresFaceDetection,
        'isScreenEffect': isScreenEffect,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

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

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (slug != null) json['slug'] = slug;
    if (effectType != null) json['effectType'] = effectType;
    if (emoji != null) json['emoji'] = emoji;
    if (assetUrl != null) json['assetUrl'] = assetUrl;
    if (previewColorHex != null) json['previewColorHex'] = previewColorHex;
    if (labelKey != null) json['labelKey'] = labelKey;
    if (requiresFaceDetection != null) {
      json['requiresFaceDetection'] = requiresFaceDetection;
    }
    if (isScreenEffect != null) json['isScreenEffect'] = isScreenEffect;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
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
  overview,
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
