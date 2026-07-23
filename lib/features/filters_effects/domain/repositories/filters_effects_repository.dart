import '../entities/effect_placement_entities.dart';
import '../entities/filter_settings_entities.dart';
import '../entities/filters_effects_entities.dart';

abstract class FiltersEffectsRepository {
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

  Future<String> uploadEffectAsset(List<int> bytes, String filename);

  Future<FilterLutUploadResult> uploadFilterLut(List<int> bytes, String filename);
}
