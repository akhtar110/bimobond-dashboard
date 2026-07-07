import '../entities/filters_effects_entities.dart';

abstract class FiltersEffectsRepository {
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
