import 'package:dio/dio.dart';

import '../../domain/entities/filters_effects_entities.dart';

abstract class FiltersEffectsRemoteDataSource {
  Future<FiltersEffectsOverviewEntity> getOverview();
  Future<CameraStudioCatalogEntity> getCatalog();
  Future<List<CameraFilterEntity>> getFilters();
  Future<CameraFilterEntity> getFilter(String id);
  Future<CameraFilterEntity> createFilter(CreateFilterRequest request);
  Future<CameraFilterEntity> updateFilter(String id, UpdateFilterRequest request);
  Future<CameraFilterEntity> activateFilter(String id);
  Future<CameraFilterEntity> deactivateFilter(String id);
  Future<void> deleteFilter(String id);
  Future<List<CameraFilterCategoryEntity>> getFilterCategories();
  Future<CameraFilterCategoryEntity> createFilterCategory(
    CreateCategoryRequest request,
  );
  Future<CameraFilterCategoryEntity> updateFilterCategory(
    String id,
    UpdateCategoryRequest request,
  );
  Future<List<CameraFilterCategoryEntity>> reorderFilterCategories(
    List<CategoryReorderItem> items,
  );
  Future<CameraFilterCategoryEntity> assignFiltersToCategory(
    String categoryId,
    List<FilterAssignmentItem> filters,
  );
  Future<void> deleteFilterCategory(String id);
  Future<List<CameraEffectEntity>> getEffects();
  Future<CameraEffectEntity> getEffect(String id);
  Future<CameraEffectEntity> createEffect(CreateEffectRequest request);
  Future<CameraEffectEntity> updateEffect(String id, UpdateEffectRequest request);
  Future<CameraEffectEntity> activateEffect(String id);
  Future<CameraEffectEntity> deactivateEffect(String id);
  Future<void> deleteEffect(String id);
  Future<List<CameraEffectCategoryEntity>> getEffectCategories();
  Future<CameraEffectCategoryEntity> createEffectCategory(
    CreateCategoryRequest request,
  );
  Future<CameraEffectCategoryEntity> updateEffectCategory(
    String id,
    UpdateCategoryRequest request,
  );
  Future<List<CameraEffectCategoryEntity>> reorderEffectCategories(
    List<CategoryReorderItem> items,
  );
  Future<CameraEffectCategoryEntity> assignEffectsToCategory(
    String categoryId,
    List<EffectAssignmentItem> effects,
  );
  Future<void> deleteEffectCategory(String id);
  Future<CatalogPublishResultEntity> publishCatalog(
    PublishCatalogRequest request,
  );
  Future<CameraStudioCatalogEntity> seedCatalog();
}

class FiltersEffectsRemoteDataSourceImpl implements FiltersEffectsRemoteDataSource {
  FiltersEffectsRemoteDataSourceImpl(this._dio);

  final Dio _dio;
  static const _base = '/camera-studio/admin';

  @override
  Future<FiltersEffectsOverviewEntity> getOverview() async {
    final response = await _dio.get('$_base/overview');
    return FiltersEffectsOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraStudioCatalogEntity> getCatalog() async {
    final response = await _dio.get('$_base/catalog');
    return CameraStudioCatalogModel.fromJson(_map(response.data));
  }

  @override
  Future<List<CameraFilterEntity>> getFilters() async {
    final response = await _dio.get('$_base/filters');
    return _list(response.data)
        .map((e) => CameraFilterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CameraFilterEntity> getFilter(String id) async {
    final response = await _dio.get('$_base/filters/$id');
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraFilterEntity> createFilter(CreateFilterRequest request) async {
    final response = await _dio.post('$_base/filters', data: request.toJson());
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraFilterEntity> updateFilter(
    String id,
    UpdateFilterRequest request,
  ) async {
    final response =
        await _dio.patch('$_base/filters/$id', data: request.toJson());
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraFilterEntity> activateFilter(String id) async {
    final response = await _dio.patch('$_base/filters/$id/activate');
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraFilterEntity> deactivateFilter(String id) async {
    final response = await _dio.patch('$_base/filters/$id/deactivate');
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteFilter(String id) async {
    await _dio.delete('$_base/filters/$id');
  }

  @override
  Future<List<CameraFilterCategoryEntity>> getFilterCategories() async {
    final response = await _dio.get('$_base/filter-categories');
    return _list(response.data)
        .map(
          (e) => CameraFilterCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<CameraFilterCategoryEntity> createFilterCategory(
    CreateCategoryRequest request,
  ) async {
    final response =
        await _dio.post('$_base/filter-categories', data: request.toJson());
    return CameraFilterCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraFilterCategoryEntity> updateFilterCategory(
    String id,
    UpdateCategoryRequest request,
  ) async {
    final response = await _dio.patch(
      '$_base/filter-categories/$id',
      data: request.toJson(),
    );
    return CameraFilterCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<List<CameraFilterCategoryEntity>> reorderFilterCategories(
    List<CategoryReorderItem> items,
  ) async {
    final response = await _dio.patch(
      '$_base/filter-categories/reorder',
      data: {'items': items.map((e) => e.toJson()).toList()},
    );
    return _list(response.data)
        .map(
          (e) => CameraFilterCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<CameraFilterCategoryEntity> assignFiltersToCategory(
    String categoryId,
    List<FilterAssignmentItem> filters,
  ) async {
    final response = await _dio.put(
      '$_base/filter-categories/$categoryId/filters',
      data: {'filters': filters.map((e) => e.toJson()).toList()},
    );
    return CameraFilterCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteFilterCategory(String id) async {
    await _dio.delete('$_base/filter-categories/$id');
  }

  @override
  Future<List<CameraEffectEntity>> getEffects() async {
    final response = await _dio.get('$_base/effects');
    return _list(response.data)
        .map((e) => CameraEffectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CameraEffectEntity> getEffect(String id) async {
    final response = await _dio.get('$_base/effects/$id');
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraEffectEntity> createEffect(CreateEffectRequest request) async {
    final response = await _dio.post('$_base/effects', data: request.toJson());
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraEffectEntity> updateEffect(
    String id,
    UpdateEffectRequest request,
  ) async {
    final response =
        await _dio.patch('$_base/effects/$id', data: request.toJson());
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraEffectEntity> activateEffect(String id) async {
    final response = await _dio.patch('$_base/effects/$id/activate');
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraEffectEntity> deactivateEffect(String id) async {
    final response = await _dio.patch('$_base/effects/$id/deactivate');
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteEffect(String id) async {
    await _dio.delete('$_base/effects/$id');
  }

  @override
  Future<List<CameraEffectCategoryEntity>> getEffectCategories() async {
    final response = await _dio.get('$_base/effect-categories');
    return _list(response.data)
        .map(
          (e) => CameraEffectCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<CameraEffectCategoryEntity> createEffectCategory(
    CreateCategoryRequest request,
  ) async {
    final response =
        await _dio.post('$_base/effect-categories', data: request.toJson());
    return CameraEffectCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraEffectCategoryEntity> updateEffectCategory(
    String id,
    UpdateCategoryRequest request,
  ) async {
    final response = await _dio.patch(
      '$_base/effect-categories/$id',
      data: request.toJson(),
    );
    return CameraEffectCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<List<CameraEffectCategoryEntity>> reorderEffectCategories(
    List<CategoryReorderItem> items,
  ) async {
    final response = await _dio.patch(
      '$_base/effect-categories/reorder',
      data: {'items': items.map((e) => e.toJson()).toList()},
    );
    return _list(response.data)
        .map(
          (e) => CameraEffectCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<CameraEffectCategoryEntity> assignEffectsToCategory(
    String categoryId,
    List<EffectAssignmentItem> effects,
  ) async {
    final response = await _dio.put(
      '$_base/effect-categories/$categoryId/effects',
      data: {'effects': effects.map((e) => e.toJson()).toList()},
    );
    return CameraEffectCategoryModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteEffectCategory(String id) async {
    await _dio.delete('$_base/effect-categories/$id');
  }

  @override
  Future<CatalogPublishResultEntity> publishCatalog(
    PublishCatalogRequest request,
  ) async {
    final response =
        await _dio.post('$_base/catalog/publish', data: request.toJson());
    return CatalogPublishResultModel.fromJson(_map(response.data));
  }

  @override
  Future<CameraStudioCatalogEntity> seedCatalog() async {
    final response = await _dio.post('$_base/seed');
    return CameraStudioCatalogModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    throw Exception('Invalid camera studio API response');
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
      if (nested is Map<String, dynamic> && nested['data'] is List) {
        return nested['data'] as List;
      }
    }
    return const [];
  }
}

class FiltersEffectsOverviewModel extends FiltersEffectsOverviewEntity {
  const FiltersEffectsOverviewModel({
    required super.filters,
    required super.filterCategories,
    required super.effects,
    required super.effectCategories,
    required super.catalogVersion,
    super.catalogPublishedAt,
  });

  factory FiltersEffectsOverviewModel.fromJson(Map<String, dynamic> json) {
    return FiltersEffectsOverviewModel(
      filters: _countSummary(json['filters']),
      filterCategories: _countSummary(json['filterCategories']),
      effects: _countSummary(json['effects']),
      effectCategories: _countSummary(json['effectCategories']),
      catalogVersion: json['catalogVersion']?.toString() ?? '',
      catalogPublishedAt: _date(json['catalogPublishedAt']),
    );
  }
}

FiltersEffectsCountSummary _countSummary(dynamic value) {
  final map = value is Map<String, dynamic> ? value : const <String, dynamic>{};
  return FiltersEffectsCountSummary(
    total: _int(map['total']),
    active: _int(map['active']),
    inactive: _int(map['inactive']),
  );
}

class CameraFilterModel extends CameraFilterEntity {
  const CameraFilterModel({
    required super.id,
    required super.slug,
    required super.engineType,
    required super.engineKey,
    super.labelKey,
    super.customLabel,
    super.thumbnailUrl,
    super.previewColorHex,
    super.isOriginal,
    super.isBeautyDefault,
    super.isActive,
    super.sortOrder,
    super.createdAt,
    super.updatedAt,
  });

  factory CameraFilterModel.fromJson(Map<String, dynamic> json) {
    return CameraFilterModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      engineType: json['engineType']?.toString() ?? 'camerawesome',
      engineKey: json['engineKey']?.toString() ?? '',
      labelKey: json['labelKey']?.toString(),
      customLabel: json['customLabel']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      previewColorHex: json['previewColorHex']?.toString(),
      isOriginal: json['isOriginal'] == true,
      isBeautyDefault: json['isBeautyDefault'] == true,
      isActive: json['isActive'] != false,
      sortOrder: _int(json['sortOrder']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class CameraFilterCategoryModel extends CameraFilterCategoryEntity {
  const CameraFilterCategoryModel({
    required super.id,
    required super.slug,
    required super.labelKey,
    required super.sortOrder,
    required super.isActive,
    super.filters,
    super.createdAt,
    super.updatedAt,
  });

  factory CameraFilterCategoryModel.fromJson(Map<String, dynamic> json) {
    final filters = (json['filters'] as List? ?? [])
        .map((e) => CameraFilterModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CameraFilterCategoryModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      labelKey: json['labelKey']?.toString() ?? '',
      sortOrder: _int(json['sortOrder']),
      isActive: json['isActive'] != false,
      filters: filters,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class CameraEffectModel extends CameraEffectEntity {
  const CameraEffectModel({
    required super.id,
    required super.slug,
    required super.effectType,
    super.emoji,
    super.assetUrl,
    super.previewColorHex,
    required super.labelKey,
    super.requiresFaceDetection,
    super.isScreenEffect,
    super.isActive,
    super.sortOrder,
    super.createdAt,
    super.updatedAt,
  });

  factory CameraEffectModel.fromJson(Map<String, dynamic> json) {
    return CameraEffectModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      effectType: json['effectType']?.toString() ?? '',
      emoji: json['emoji']?.toString(),
      assetUrl: json['assetUrl']?.toString(),
      previewColorHex: json['previewColorHex']?.toString(),
      labelKey: json['labelKey']?.toString() ?? '',
      requiresFaceDetection: json['requiresFaceDetection'] == true,
      isScreenEffect: json['isScreenEffect'] == true,
      isActive: json['isActive'] != false,
      sortOrder: _int(json['sortOrder']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class CameraEffectCategoryModel extends CameraEffectCategoryEntity {
  const CameraEffectCategoryModel({
    required super.id,
    required super.slug,
    required super.labelKey,
    required super.sortOrder,
    required super.isActive,
    super.effects,
    super.createdAt,
    super.updatedAt,
  });

  factory CameraEffectCategoryModel.fromJson(Map<String, dynamic> json) {
    final effects = (json['effects'] as List? ?? [])
        .map((e) => CameraEffectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CameraEffectCategoryModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      labelKey: json['labelKey']?.toString() ?? '',
      sortOrder: _int(json['sortOrder']),
      isActive: json['isActive'] != false,
      effects: effects,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class CameraStudioCatalogModel extends CameraStudioCatalogEntity {
  const CameraStudioCatalogModel({
    required super.version,
    required super.filterCategories,
    required super.effectCategories,
  });

  factory CameraStudioCatalogModel.fromJson(Map<String, dynamic> json) {
    final filterCategories = (json['filterCategories'] as List? ?? [])
        .map(
          (e) => CameraFilterCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final effectCategories = (json['effectCategories'] as List? ?? [])
        .map(
          (e) => CameraEffectCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return CameraStudioCatalogModel(
      version: json['version']?.toString() ?? '',
      filterCategories: filterCategories,
      effectCategories: effectCategories,
    );
  }
}

class CatalogPublishResultModel extends CatalogPublishResultEntity {
  const CatalogPublishResultModel({
    required super.id,
    required super.version,
    required super.publishedAt,
    super.notes,
  });

  factory CatalogPublishResultModel.fromJson(Map<String, dynamic> json) {
    return CatalogPublishResultModel(
      id: json['id']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      publishedAt:
          _date(json['publishedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      notes: json['notes']?.toString(),
    );
  }
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Known CamerAwesome engine keys for filter dropdowns.
const kCameraAwesomeEngineKeys = [
  'Original',
  'Amaro',
  'Juno',
  'Lark',
  'Addictive Red',
  'Addictive Blue',
  'Clarendon',
  'Reyes',
  'Aden',
  'Perpetua',
  'Walden',
  'Ginza',
  'Sierra',
  'Hefe',
  'Inkwell',
  'Moon',
  'Willow',
  'Brannan',
  'Stinson',
  'Sutro',
  'Hudson',
  'LoFi',
  'Slumber',
  'Dogpatch',
  'Brooklyn',
  'Gingham',
  'XProII',
  'Ludwig',
  'Crema',
  'Ashby',
];
