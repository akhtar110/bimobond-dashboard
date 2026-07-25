import 'dart:typed_data';

import '../../domain/entities/effect_placement_entities.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/repositories/filters_effects_repository.dart';
import '../datasources/filters_effects_remote_datasource.dart';

class FiltersEffectsRepositoryImpl implements FiltersEffectsRepository {
  const FiltersEffectsRepositoryImpl(this._remote);

  final FiltersEffectsRemoteDataSource _remote;

  @override
  Future<FiltersEffectsOverviewEntity> getOverview() => _remote.getOverview();

  @override
  Future<CameraStudioCatalogEntity> getCatalog() => _remote.getCatalog();

  @override
  Future<PaginatedCameraFiltersEntity> getFilters(
    FiltersEffectsListQuery query,
  ) => _remote.getFilters(query);

  @override
  Future<CameraFilterEntity> getFilter(String id) => _remote.getFilter(id);

  @override
  Future<FilterSettingsSchemaEntity> getFilterSettingsSchema() =>
      _remote.getFilterSettingsSchema();

  @override
  Future<CameraFilterEntity> createFilter(CreateFilterRequest request) =>
      _remote.createFilter(request);

  @override
  Future<CameraFilterEntity> updateFilter(
    String id,
    UpdateFilterRequest request,
  ) => _remote.updateFilter(id, request);

  @override
  Future<CameraFilterEntity> activateFilter(String id) =>
      _remote.activateFilter(id);

  @override
  Future<CameraFilterEntity> deactivateFilter(String id) =>
      _remote.deactivateFilter(id);

  @override
  Future<void> deleteFilter(String id) => _remote.deleteFilter(id);

  @override
  Future<BulkCameraFiltersResult> bulkFilters(BulkCameraFiltersRequest request) =>
      _remote.bulkFilters(request);

  @override
  Future<PaginatedCameraFiltersEntity> bulkUpdateFilters(
    BulkUpdateCameraFiltersRequest request,
  ) => _remote.bulkUpdateFilters(request);

  @override
  Future<List<CameraFilterCategoryEntity>> getFilterCategories() =>
      _remote.getFilterCategories();

  @override
  Future<CameraFilterCategoryEntity> createFilterCategory(
    CreateCategoryRequest request,
  ) => _remote.createFilterCategory(request);

  @override
  Future<CameraFilterCategoryEntity> updateFilterCategory(
    String id,
    UpdateCategoryRequest request,
  ) => _remote.updateFilterCategory(id, request);

  @override
  Future<List<CameraFilterCategoryEntity>> reorderFilterCategories(
    List<CategoryReorderItem> items,
  ) => _remote.reorderFilterCategories(items);

  @override
  Future<CameraFilterCategoryEntity> assignFiltersToCategory(
    String categoryId,
    List<FilterAssignmentItem> filters,
  ) => _remote.assignFiltersToCategory(categoryId, filters);

  @override
  Future<void> deleteFilterCategory(String id) =>
      _remote.deleteFilterCategory(id);

  @override
  Future<PaginatedCameraEffectsEntity> getEffects(
    FiltersEffectsListQuery query,
  ) => _remote.getEffects(query);

  @override
  Future<CameraEffectEntity> getEffect(String id) => _remote.getEffect(id);

  @override
  Future<EffectPlacementSchemaEntity> getEffectPlacementSchema() =>
      _remote.getEffectPlacementSchema();

  @override
  Future<CameraEffectEntity> createEffect(CreateEffectRequest request) =>
      _remote.createEffect(request);

  @override
  Future<CameraEffectEntity> updateEffect(
    String id,
    UpdateEffectRequest request,
  ) => _remote.updateEffect(id, request);

  @override
  Future<CameraEffectEntity> activateEffect(String id) =>
      _remote.activateEffect(id);

  @override
  Future<CameraEffectEntity> deactivateEffect(String id) =>
      _remote.deactivateEffect(id);

  @override
  Future<void> deleteEffect(String id) => _remote.deleteEffect(id);

  @override
  Future<BulkCameraEffectsResult> bulkEffects(BulkCameraEffectsRequest request) =>
      _remote.bulkEffects(request);

  @override
  Future<List<CameraEffectCategoryEntity>> getEffectCategories() =>
      _remote.getEffectCategories();

  @override
  Future<CameraEffectCategoryEntity> createEffectCategory(
    CreateCategoryRequest request,
  ) => _remote.createEffectCategory(request);

  @override
  Future<CameraEffectCategoryEntity> updateEffectCategory(
    String id,
    UpdateCategoryRequest request,
  ) => _remote.updateEffectCategory(id, request);

  @override
  Future<List<CameraEffectCategoryEntity>> reorderEffectCategories(
    List<CategoryReorderItem> items,
  ) => _remote.reorderEffectCategories(items);

  @override
  Future<CameraEffectCategoryEntity> assignEffectsToCategory(
    String categoryId,
    List<EffectAssignmentItem> effects,
  ) => _remote.assignEffectsToCategory(categoryId, effects);

  @override
  Future<void> deleteEffectCategory(String id) =>
      _remote.deleteEffectCategory(id);

  @override
  Future<CatalogPublishResultEntity> publishCatalog(
    PublishCatalogRequest request,
  ) => _remote.publishCatalog(request);

  @override
  Future<CatalogSeedResultEntity> seedCatalog() => _remote.seedCatalog();

  @override
  Future<String> uploadEffectAsset(List<int> bytes, String filename) =>
      _remote.uploadEffectAsset(Uint8List.fromList(bytes), filename);

  @override
  Future<FilterLutUploadResult> uploadFilterLut(
    List<int> bytes,
    String filename,
  ) => _remote.uploadFilterLut(Uint8List.fromList(bytes), filename);
}
