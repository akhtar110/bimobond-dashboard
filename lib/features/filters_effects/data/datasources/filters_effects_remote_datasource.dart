import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/effect_placement_entities.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../models/effect_placement_schema_model.dart';
import '../models/filter_settings_schema_model.dart';

abstract class FiltersEffectsRemoteDataSource {
  Future<FiltersEffectsOverviewEntity> getOverview();
  Future<CameraStudioCatalogEntity> getCatalog();
  Future<PaginatedCameraFiltersEntity> getFilters(
    FiltersEffectsListQuery query,
  );
  Future<CameraFilterEntity> getFilter(String id);
  Future<FilterSettingsSchemaEntity> getFilterSettingsSchema();
  Future<CameraFilterEntity> createFilter(CreateFilterRequest request);
  Future<CameraFilterEntity> updateFilter(
    String id,
    UpdateFilterRequest request,
  );
  Future<CameraFilterEntity> activateFilter(String id);
  Future<CameraFilterEntity> deactivateFilter(String id);
  Future<void> deleteFilter(String id);

  Future<BulkCameraFiltersResult> bulkFilters(BulkCameraFiltersRequest request);
  Future<PaginatedCameraFiltersEntity> bulkUpdateFilters(
    BulkUpdateCameraFiltersRequest request,
  );
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
  Future<PaginatedCameraEffectsEntity> getEffects(
    FiltersEffectsListQuery query,
  );
  Future<CameraEffectEntity> getEffect(String id);
  Future<EffectPlacementSchemaEntity> getEffectPlacementSchema();
  Future<CameraEffectEntity> createEffect(CreateEffectRequest request);
  Future<CameraEffectEntity> updateEffect(
    String id,
    UpdateEffectRequest request,
  );
  Future<CameraEffectEntity> activateEffect(String id);
  Future<CameraEffectEntity> deactivateEffect(String id);
  Future<void> deleteEffect(String id);

  Future<BulkCameraEffectsResult> bulkEffects(BulkCameraEffectsRequest request);
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
  Future<CatalogSeedResultEntity> seedCatalog();

  /// Uploads a PNG/sticker via `POST /posts/upload` and returns an absolute URL.
  Future<String> uploadEffectAsset(Uint8List bytes, String filename);

  /// Uploads a LUT file via `POST /camera-studio/admin/filters/lut/upload`.
  Future<FilterLutUploadResult> uploadFilterLut(
    Uint8List bytes,
    String filename,
  );
}

class FiltersEffectsRemoteDataSourceImpl
    implements FiltersEffectsRemoteDataSource {
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
  Future<PaginatedCameraFiltersEntity> getFilters(
    FiltersEffectsListQuery query,
  ) async {
    final response = await _dio.get(
      '$_base/filters',
      queryParameters: query.toQueryParameters(),
    );
    return _parsePaginatedFilters(response.data);
  }

  @override
  Future<CameraFilterEntity> getFilter(String id) async {
    final response = await _dio.get('$_base/filters/$id');
    return CameraFilterModel.fromJson(_map(response.data));
  }

  @override
  Future<FilterSettingsSchemaEntity> getFilterSettingsSchema() async {
    final response = await _dio.get('/camera-studio/filter-settings/schema');
    return FilterSettingsSchemaModel.fromJson(_map(response.data));
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
    final response = await _dio.patch(
      '$_base/filters/$id',
      data: request.toJson(),
    );
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
  Future<BulkCameraFiltersResult> bulkFilters(
    BulkCameraFiltersRequest request,
  ) async {
    final response = await _dio.post(
      '$_base/filters/bulk',
      data: request.toJson(),
    );
    return BulkCameraFiltersResultModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedCameraFiltersEntity> bulkUpdateFilters(
    BulkUpdateCameraFiltersRequest request,
  ) async {
    final response = await _dio.patch(
      '$_base/filters/bulk',
      data: request.toJson(),
    );
    return _parsePaginatedFilters(response.data);
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
    final response = await _dio.post(
      '$_base/filter-categories',
      data: request.toJson(),
    );
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
  Future<PaginatedCameraEffectsEntity> getEffects(
    FiltersEffectsListQuery query,
  ) async {
    final response = await _dio.get(
      '$_base/effects',
      queryParameters: query.toEffectQueryParameters(),
    );
    return _parsePaginatedEffects(response.data);
  }

  @override
  Future<CameraEffectEntity> getEffect(String id) async {
    final response = await _dio.get('$_base/effects/$id');
    return CameraEffectModel.fromJson(_map(response.data));
  }

  @override
  Future<EffectPlacementSchemaEntity> getEffectPlacementSchema() async {
    final response = await _dio.get('/camera-studio/effect-placement/schema');
    return EffectPlacementSchemaModel.fromJson(_map(response.data));
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
    final response = await _dio.patch(
      '$_base/effects/$id',
      data: request.toJson(),
    );
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
  Future<BulkCameraEffectsResult> bulkEffects(
    BulkCameraEffectsRequest request,
  ) async {
    final response = await _dio.post(
      '$_base/effects/bulk',
      data: request.toJson(),
    );
    return BulkCameraEffectsResultModel.fromJson(_map(response.data));
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
    final response = await _dio.post(
      '$_base/effect-categories',
      data: request.toJson(),
    );
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
    final response = await _dio.post(
      '$_base/catalog/publish',
      data: request.toJson(),
    );
    return CatalogPublishResultModel.fromJson(_map(response.data));
  }

  @override
  Future<CatalogSeedResultEntity> seedCatalog() async {
    final response = await _dio.post('$_base/seed');
    return CatalogSeedResultModel.fromJson(_map(response.data));
  }

  @override
  Future<String> uploadEffectAsset(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw Exception('Asset upload failed: empty file bytes');
    }

    final formData = FormData();
    formData.files.add(
      MapEntry('files', MultipartFile.fromBytes(bytes, filename: filename)),
    );

    final response = await _dio.post(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final url = _extractPostsUploadUrl(response.data);
    if (url == null || url.isEmpty) {
      throw Exception(
        'Asset upload failed: no URL returned from server: ${response.data}',
      );
    }

    return resolveMediaUrl(url) ?? url;
  }

  /// Parses `POST /posts/upload` responses across Map/List shapes (web-safe).
  String? _extractPostsUploadUrl(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      return _parseUploadUrl(data);
    }

    if (data is List && data.isNotEmpty) {
      for (final item in data) {
        final parsed = _parseUploadUrl(item);
        if (parsed.isNotEmpty) return parsed;
      }
      return null;
    }

    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final topUrls = map['urls'];
    if (topUrls is List && topUrls.isNotEmpty) {
      for (final item in topUrls) {
        final parsed = _parseUploadUrl(item);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      final nestedUrls = nestedMap['urls'];
      if (nestedUrls is List && nestedUrls.isNotEmpty) {
        for (final item in nestedUrls) {
          final parsed = _parseUploadUrl(item);
          if (parsed.isNotEmpty) return parsed;
        }
      }
      final fromNested = _extractPostsUploadUrl(nestedMap);
      if (fromNested != null && fromNested.isNotEmpty) return fromNested;
    } else if (nested is List || nested is String) {
      final fromNested = _extractPostsUploadUrl(nested);
      if (fromNested != null && fromNested.isNotEmpty) return fromNested;
    }

    final direct = _parseUploadUrl(
      map['url'] ?? map['path'] ?? map['location'],
    );
    return direct.isEmpty ? null : direct;
  }

  @override
  Future<FilterLutUploadResult> uploadFilterLut(
    Uint8List bytes,
    String filename,
  ) async {
    final normalized = filename.trim().toLowerCase();
    if (!normalized.endsWith('.cube') &&
        !normalized.endsWith('.png') &&
        !normalized.endsWith('.3dl')) {
      throw Exception('Unsupported LUT file type. Use .cube, .3dl, or .png');
    }
    return _uploadAdminLut(bytes, filename);
  }

  Future<FilterLutUploadResult> _uploadAdminLut(
    Uint8List bytes,
    String filename,
  ) async {
    final formData = FormData();
    formData.files.add(
      MapEntry('file', MultipartFile.fromBytes(bytes, filename: filename)),
    );

    final response = await _dio.post(
      '$_base/filters/lut/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    return _parseLutUploadResult(_map(response.data), filename);
  }

  FilterLutUploadResult _parseLutUploadResult(
    Map<String, dynamic> map,
    String fallbackFilename,
  ) {
    final lutUrl = _readLutUrl(map);
    if (lutUrl == null || lutUrl.isEmpty) {
      throw Exception('LUT upload failed: no lutUrl returned');
    }

    final lutAsset = _readLutAsset(map, fallbackFilename);

    return FilterLutUploadResult(
      lutUrl: resolveMediaUrl(lutUrl) ?? lutUrl,
      lutAsset: lutAsset,
      sourceFilename: map['originalName']?.toString().trim().isNotEmpty == true
          ? map['originalName'].toString().trim()
          : fallbackFilename,
    );
  }

  String _readLutAsset(Map<String, dynamic> map, String fallbackFilename) {
    for (final key in ['lutAsset', 'filename']) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallbackFilename.split(RegExp(r'[/\\]')).last;
  }

  String? _readLutUrl(Map<String, dynamic> map) {
    final direct = map['lutUrl']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final url = map['url']?.toString().trim();
    if (url != null && url.isNotEmpty) return url;

    final urls = map['urls'];
    if (urls is List && urls.isNotEmpty) {
      return _parseUploadUrl(urls.first);
    }

    final nested = map['data'];
    if (nested is Map<String, dynamic>) {
      return _readLutUrl(nested);
    }
    return null;
  }

  PaginatedCameraFiltersEntity _parsePaginatedFilters(dynamic data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final items = _list(data)
        .map((e) => CameraFilterModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metaMap = map['meta'];
    final meta = metaMap is Map<String, dynamic>
        ? FiltersEffectsPaginationMetaModel.fromJson(metaMap)
        : FiltersEffectsPaginationMeta(
            total: items.length,
            page: 1,
            limit: items.length,
            totalPages: 1,
          );
    return PaginatedCameraFiltersEntity(data: items, meta: meta);
  }

  PaginatedCameraEffectsEntity _parsePaginatedEffects(dynamic data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final items = _list(data)
        .map((e) => CameraEffectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metaMap = map['meta'];
    final meta = metaMap is Map<String, dynamic>
        ? FiltersEffectsPaginationMetaModel.fromJson(metaMap)
        : FiltersEffectsPaginationMeta(
            total: items.length,
            page: 1,
            limit: items.length,
            totalPages: 1,
          );
    return PaginatedCameraEffectsEntity(data: items, meta: meta);
  }

  String _parseUploadUrl(dynamic entry) {
    if (entry is String) return entry;
    if (entry is Map<String, dynamic>) {
      return (entry['url'] ?? entry['path'] ?? '').toString();
    }
    return '';
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Prefer unwrapped admin responses. Only peel a nested `data` map when
      // the outer map looks like an envelope (has success/message and no id).
      if (data['data'] is Map<String, dynamic> &&
          !data.containsKey('id') &&
          !data.containsKey('slug') &&
          !data.containsKey('version') &&
          !data.containsKey('filterCategories') &&
          !data.containsKey('colorFilterCategories')) {
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
    throw Exception('Invalid camera studio list response');
  }
}

class FiltersEffectsOverviewModel extends FiltersEffectsOverviewEntity {
  const FiltersEffectsOverviewModel({
    required super.filters,
    required super.filterCategories,
    required super.effects,
    required super.effectCategories,
    super.catalogVersion,
    super.catalogPublishedAt,
  });

  factory FiltersEffectsOverviewModel.fromJson(Map<String, dynamic> json) {
    final categoryCounts =
        json['filterCategories'] ?? json['colorFilterCategories'];
    return FiltersEffectsOverviewModel(
      filters: _countSummary(json['filters']),
      filterCategories: _countSummary(categoryCounts),
      effects: _countSummary(json['effects']),
      effectCategories: _countSummary(json['effectCategories']),
      catalogVersion: json['catalogVersion']?.toString(),
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
    required super.label,
    super.customLabel,
    super.labelKey,
    super.emoji,
    super.thumbnailUrl,
    super.previewColorHex,
    super.filterSettings = FilterSettingsEntity.empty,
    super.isOriginal = false,
    super.isBeautyDefault = false,
    super.isActive = true,
    super.sortOrder = 0,
    super.createdAt,
    super.updatedAt,
    super.renderType = 'lut',
    super.colorMatrix = const [],
    super.lutUrl,
    super.lutAsset,
    super.adjustments = const CameraFilterAdjustments(),
  });

  factory CameraFilterModel.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['filterSettings'];
    final FilterSettingsEntity filterSettingsEntity = rawSettings is Map<String, dynamic>
        ? FilterSettingsEntity.fromJson(rawSettings)
        : (rawSettings is Map ? FilterSettingsEntity.fromJson(Map<String, dynamic>.from(rawSettings)) : FilterSettingsEntity.empty);

    final label =
        json['label']?.toString() ??
        json['customLabel']?.toString() ??
        json['slug']?.toString() ??
        '';
    return CameraFilterModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      label: label,
      customLabel: json['customLabel']?.toString(),
      labelKey: json['labelKey']?.toString(),
      emoji: json['emoji']?.toString(),
      thumbnailUrl:
          resolveMediaUrl(json['thumbnailUrl']?.toString()) ??
          json['thumbnailUrl']?.toString(),
      previewColorHex: json['previewColorHex']?.toString(),
      filterSettings: filterSettingsEntity,
      isOriginal: json['isOriginal'] == true,
      isBeautyDefault: json['isBeautyDefault'] == true,
      isActive: json['isActive'] != false,
      sortOrder: _int(json['sortOrder']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      renderType: CameraFilterRenderTypeApi.fromResponse(
        json['renderType']?.toString() ?? '',
      ),
      colorMatrix: _parseColorMatrix(json['colorMatrix']),
      lutUrl:
          resolveMediaUrl(json['lutUrl']?.toString()) ??
          json['lutUrl']?.toString(),
      lutAsset: json['lutAsset']?.toString(),
      adjustments: _parseAdjustments(json['adjustments']),
    );
  }
}

class CameraFilterCategoryModel extends CameraFilterCategoryEntity {
  const CameraFilterCategoryModel({
    required super.id,
    required super.slug,
    required super.label,
    super.labelKey,
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
    final label =
        json['label']?.toString() ??
        json['labelKey']?.toString() ??
        json['slug']?.toString() ??
        '';
    return CameraFilterCategoryModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      label: label,
      labelKey: json['labelKey']?.toString(),
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
    required super.renderType,
    required super.label,
    super.labelKey,
    super.emoji,
    super.thumbnailUrl,
    super.previewColorHex,
    super.assetUrl,
    super.assetAsset,
    super.anchor,
    super.stickers,
    super.distortionPreset,
    super.isActive,
    super.sortOrder,
    super.createdAt,
    super.updatedAt,
  });

  factory CameraEffectModel.fromJson(Map<String, dynamic> json) {
    final rawAnchor = json['anchor'];
    final rawStickers = json['stickers'];
    final label =
        json['label']?.toString() ??
        json['labelKey']?.toString() ??
        json['slug']?.toString() ??
        '';
    final distortion = json['distortionPreset']?.toString();
    return CameraEffectModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      renderType: CameraEffectRenderTypeApi.fromResponse(
        json['renderType']?.toString() ?? '',
      ),
      label: label,
      labelKey: json['labelKey']?.toString(),
      emoji: json['emoji']?.toString(),
      thumbnailUrl:
          resolveMediaUrl(json['thumbnailUrl']?.toString()) ??
          json['thumbnailUrl']?.toString(),
      previewColorHex: json['previewColorHex']?.toString(),
      assetUrl:
          resolveMediaUrl(json['assetUrl']?.toString()) ??
          json['assetUrl']?.toString(),
      assetAsset: json['assetAsset']?.toString(),
      anchor: rawAnchor is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawAnchor)
          : const {},
      stickers: rawStickers is List
          ? rawStickers
                .whereType<Map>()
                .map(
                  (e) => CameraEffectStickerLayer.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      distortionPreset: distortion == null || distortion.isEmpty
          ? null
          : CameraDistortionPresetApi.fromResponse(distortion),
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
    required super.label,
    super.labelKey,
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
    final label =
        json['label']?.toString() ??
        json['labelKey']?.toString() ??
        json['slug']?.toString() ??
        '';
    return CameraEffectCategoryModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      label: label,
      labelKey: json['labelKey']?.toString(),
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
    super.version,
    required super.filterCategories,
    required super.effectCategories,
  });

  factory CameraStudioCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawFilterCategories =
        json['colorFilterCategories'] ?? json['filterCategories'];
    final filterCategories = (rawFilterCategories as List? ?? [])
        .map(
          (e) => CameraFilterCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final effectCategories = (json['effectCategories'] as List? ?? [])
        .map(
          (e) => CameraEffectCategoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final version = json['version']?.toString();
    return CameraStudioCatalogModel(
      version: version == null || version.isEmpty ? null : version,
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

class CatalogSeedResultModel extends CatalogSeedResultEntity {
  const CatalogSeedResultModel({required super.success, super.message});

  factory CatalogSeedResultModel.fromJson(Map<String, dynamic> json) {
    return CatalogSeedResultModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}

class FiltersEffectsPaginationMetaModel extends FiltersEffectsPaginationMeta {
  const FiltersEffectsPaginationMetaModel({
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
  });

  factory FiltersEffectsPaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return FiltersEffectsPaginationMetaModel(
      total: _int(json['total']),
      page: _int(json['page']).clamp(1, 999999),
      limit: _int(json['limit']).clamp(1, 100),
      totalPages: _int(json['totalPages']).clamp(1, 999999),
    );
  }
}

class BulkCameraFiltersResultModel extends BulkCameraFiltersResult {
  const BulkCameraFiltersResultModel({
    required super.action,
    required super.successCount,
    required super.notFoundCount,
    required super.filterIds,
    required super.notFoundIds,
  });

  factory BulkCameraFiltersResultModel.fromJson(Map<String, dynamic> json) {
    return BulkCameraFiltersResultModel(
      action: json['action']?.toString() ?? '',
      successCount: _int(json['successCount']),
      notFoundCount: _int(json['notFoundCount']),
      filterIds: _stringList(json['filterIds']),
      notFoundIds: _stringList(json['notFoundIds']),
    );
  }
}

class BulkCameraEffectsResultModel extends BulkCameraEffectsResult {
  const BulkCameraEffectsResultModel({
    required super.action,
    required super.successCount,
    required super.notFoundCount,
    required super.effectIds,
    required super.notFoundIds,
  });

  factory BulkCameraEffectsResultModel.fromJson(Map<String, dynamic> json) {
    return BulkCameraEffectsResultModel(
      action: json['action']?.toString() ?? '',
      successCount: _int(json['successCount']),
      notFoundCount: _int(json['notFoundCount']),
      effectIds: _stringList(json['effectIds']),
      notFoundIds: _stringList(json['notFoundIds']),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList(growable: false);
}

CameraFilterAdjustments _parseAdjustments(dynamic value) {
  if (value is! Map) return const CameraFilterAdjustments();
  final values = <String, num>{};
  value.forEach((key, entry) {
    if (entry is num) {
      values[key.toString()] = entry;
    } else {
      final parsed = num.tryParse(entry.toString());
      if (parsed != null) values[key.toString()] = parsed;
    }
  });
  return CameraFilterAdjustments(values);
}

List<double> _parseColorMatrix(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) {
        if (e is num) return e.toDouble();
        return double.tryParse(e.toString()) ?? 0;
      })
      .toList(growable: false);
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
