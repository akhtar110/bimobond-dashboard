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
  Future<List<CameraFilterEntity>> getFilters() => _remote.getFilters();

  @override
  Future<CameraFilterEntity> getFilter(String id) => _remote.getFilter(id);

  @override
  Future<CameraFilterEntity> createFilter(CreateFilterRequest request) =>
      _remote.createFilter(request);

  @override
  Future<CameraFilterEntity> updateFilter(
    String id,
    UpdateFilterRequest request,
  ) =>
      _remote.updateFilter(id, request);

  @override
  Future<CameraFilterEntity> activateFilter(String id) =>
      _remote.activateFilter(id);

  @override
  Future<CameraFilterEntity> deactivateFilter(String id) =>
      _remote.deactivateFilter(id);

  @override
  Future<void> deleteFilter(String id) => _remote.deleteFilter(id);

  @override
  Future<List<CameraFilterCategoryEntity>> getFilterCategories() =>
      _remote.getFilterCategories();

  @override
  Future<CameraFilterCategoryEntity> createFilterCategory(
    CreateCategoryRequest request,
  ) =>
      _remote.createFilterCategory(request);

  @override
  Future<CameraFilterCategoryEntity> updateFilterCategory(
    String id,
    UpdateCategoryRequest request,
  ) =>
      _remote.updateFilterCategory(id, request);

  @override
  Future<List<CameraFilterCategoryEntity>> reorderFilterCategories(
    List<CategoryReorderItem> items,
  ) =>
      _remote.reorderFilterCategories(items);

  @override
  Future<CameraFilterCategoryEntity> assignFiltersToCategory(
    String categoryId,
    List<FilterAssignmentItem> filters,
  ) =>
      _remote.assignFiltersToCategory(categoryId, filters);

  @override
  Future<void> deleteFilterCategory(String id) =>
      _remote.deleteFilterCategory(id);

  @override
  Future<List<CameraEffectEntity>> getEffects() => _remote.getEffects();

  @override
  Future<CameraEffectEntity> getEffect(String id) => _remote.getEffect(id);

  @override
  Future<CameraEffectEntity> createEffect(CreateEffectRequest request) =>
      _remote.createEffect(request);

  @override
  Future<CameraEffectEntity> updateEffect(
    String id,
    UpdateEffectRequest request,
  ) =>
      _remote.updateEffect(id, request);

  @override
  Future<CameraEffectEntity> activateEffect(String id) =>
      _remote.activateEffect(id);

  @override
  Future<CameraEffectEntity> deactivateEffect(String id) =>
      _remote.deactivateEffect(id);

  @override
  Future<void> deleteEffect(String id) => _remote.deleteEffect(id);

  @override
  Future<List<CameraEffectCategoryEntity>> getEffectCategories() =>
      _remote.getEffectCategories();

  @override
  Future<CameraEffectCategoryEntity> createEffectCategory(
    CreateCategoryRequest request,
  ) =>
      _remote.createEffectCategory(request);

  @override
  Future<CameraEffectCategoryEntity> updateEffectCategory(
    String id,
    UpdateCategoryRequest request,
  ) =>
      _remote.updateEffectCategory(id, request);

  @override
  Future<List<CameraEffectCategoryEntity>> reorderEffectCategories(
    List<CategoryReorderItem> items,
  ) =>
      _remote.reorderEffectCategories(items);

  @override
  Future<CameraEffectCategoryEntity> assignEffectsToCategory(
    String categoryId,
    List<EffectAssignmentItem> effects,
  ) =>
      _remote.assignEffectsToCategory(categoryId, effects);

  @override
  Future<void> deleteEffectCategory(String id) =>
      _remote.deleteEffectCategory(id);

  @override
  Future<CatalogPublishResultEntity> publishCatalog(
    PublishCatalogRequest request,
  ) =>
      _remote.publishCatalog(request);

  @override
  Future<CameraStudioCatalogEntity> seedCatalog() => _remote.seedCatalog();
}
