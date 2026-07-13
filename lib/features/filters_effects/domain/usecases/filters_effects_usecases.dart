import '../entities/effect_placement_entities.dart';
import '../entities/filter_settings_entities.dart';
import '../entities/filters_effects_entities.dart';
import '../repositories/filters_effects_repository.dart';

class GetFiltersEffectsOverviewUseCase {
  const GetFiltersEffectsOverviewUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<FiltersEffectsOverviewEntity> call() => _repository.getOverview();
}

class GetFiltersEffectsCatalogUseCase {
  const GetFiltersEffectsCatalogUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraStudioCatalogEntity> call() => _repository.getCatalog();
}

class GetCameraFiltersUseCase {
  const GetCameraFiltersUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraFilterEntity>> call() => _repository.getFilters();
}

class GetCameraFilterUseCase {
  const GetCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterEntity> call(String id) => _repository.getFilter(id);
}

class GetFilterSettingsSchemaUseCase {
  const GetFilterSettingsSchemaUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<FilterSettingsSchemaEntity> call() =>
      _repository.getFilterSettingsSchema();
}

class CreateCameraFilterUseCase {
  const CreateCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterEntity> call(
    CreateFilterRequest request, {
    FilterSettingsSchemaEntity? schema,
  }) =>
      _repository.createFilter(request, schema: schema);
}

class UpdateCameraFilterUseCase {
  const UpdateCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterEntity> call(
    String id,
    UpdateFilterRequest request, {
    FilterSettingsSchemaEntity? schema,
  }) =>
      _repository.updateFilter(id, request, schema: schema);
}

class ActivateCameraFilterUseCase {
  const ActivateCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterEntity> call(String id) => _repository.activateFilter(id);
}

class DeactivateCameraFilterUseCase {
  const DeactivateCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterEntity> call(String id) =>
      _repository.deactivateFilter(id);
}

class DeleteCameraFilterUseCase {
  const DeleteCameraFilterUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<void> call(String id) => _repository.deleteFilter(id);
}

class GetCameraFilterCategoriesUseCase {
  const GetCameraFilterCategoriesUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraFilterCategoryEntity>> call() =>
      _repository.getFilterCategories();
}

class CreateCameraFilterCategoryUseCase {
  const CreateCameraFilterCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterCategoryEntity> call(CreateCategoryRequest request) =>
      _repository.createFilterCategory(request);
}

class UpdateCameraFilterCategoryUseCase {
  const UpdateCameraFilterCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterCategoryEntity> call(
    String id,
    UpdateCategoryRequest request,
  ) =>
      _repository.updateFilterCategory(id, request);
}

class ReorderCameraFilterCategoriesUseCase {
  const ReorderCameraFilterCategoriesUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraFilterCategoryEntity>> call(
    List<CategoryReorderItem> items,
  ) =>
      _repository.reorderFilterCategories(items);
}

class AssignFiltersToCategoryUseCase {
  const AssignFiltersToCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraFilterCategoryEntity> call(
    String categoryId,
    List<FilterAssignmentItem> filters,
  ) =>
      _repository.assignFiltersToCategory(categoryId, filters);
}

class DeleteCameraFilterCategoryUseCase {
  const DeleteCameraFilterCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<void> call(String id) => _repository.deleteFilterCategory(id);
}

class GetCameraEffectsUseCase {
  const GetCameraEffectsUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraEffectEntity>> call() => _repository.getEffects();
}

class GetCameraEffectUseCase {
  const GetCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectEntity> call(String id) => _repository.getEffect(id);
}

class GetEffectPlacementSchemaUseCase {
  const GetEffectPlacementSchemaUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<EffectPlacementSchemaEntity> call() =>
      _repository.getEffectPlacementSchema();
}

class UploadEffectAssetUseCase {
  const UploadEffectAssetUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<String> call(List<int> bytes, String filename) =>
      _repository.uploadEffectAsset(bytes, filename);
}

class CreateCameraEffectUseCase {
  const CreateCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectEntity> call(CreateEffectRequest request) =>
      _repository.createEffect(request);
}

class UpdateCameraEffectUseCase {
  const UpdateCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectEntity> call(
    String id,
    UpdateEffectRequest request, {
    EffectPlacementSettingsEntity? baselinePlacement,
  }) =>
      _repository.updateEffect(
        id,
        request,
        baselinePlacement: baselinePlacement,
      );
}

class ActivateCameraEffectUseCase {
  const ActivateCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectEntity> call(String id) => _repository.activateEffect(id);
}

class DeactivateCameraEffectUseCase {
  const DeactivateCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectEntity> call(String id) =>
      _repository.deactivateEffect(id);
}

class DeleteCameraEffectUseCase {
  const DeleteCameraEffectUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<void> call(String id) => _repository.deleteEffect(id);
}

class GetCameraEffectCategoriesUseCase {
  const GetCameraEffectCategoriesUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraEffectCategoryEntity>> call() =>
      _repository.getEffectCategories();
}

class CreateCameraEffectCategoryUseCase {
  const CreateCameraEffectCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectCategoryEntity> call(CreateCategoryRequest request) =>
      _repository.createEffectCategory(request);
}

class UpdateCameraEffectCategoryUseCase {
  const UpdateCameraEffectCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectCategoryEntity> call(
    String id,
    UpdateCategoryRequest request,
  ) =>
      _repository.updateEffectCategory(id, request);
}

class ReorderCameraEffectCategoriesUseCase {
  const ReorderCameraEffectCategoriesUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<List<CameraEffectCategoryEntity>> call(
    List<CategoryReorderItem> items,
  ) =>
      _repository.reorderEffectCategories(items);
}

class AssignEffectsToCategoryUseCase {
  const AssignEffectsToCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraEffectCategoryEntity> call(
    String categoryId,
    List<EffectAssignmentItem> effects,
  ) =>
      _repository.assignEffectsToCategory(categoryId, effects);
}

class DeleteCameraEffectCategoryUseCase {
  const DeleteCameraEffectCategoryUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<void> call(String id) => _repository.deleteEffectCategory(id);
}

class PublishFiltersEffectsCatalogUseCase {
  const PublishFiltersEffectsCatalogUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CatalogPublishResultEntity> call(PublishCatalogRequest request) =>
      _repository.publishCatalog(request);
}

class SeedFiltersEffectsCatalogUseCase {
  const SeedFiltersEffectsCatalogUseCase(this._repository);

  final FiltersEffectsRepository _repository;

  Future<CameraStudioCatalogEntity> call() => _repository.seedCatalog();
}
