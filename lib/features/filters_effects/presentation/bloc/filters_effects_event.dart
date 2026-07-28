import 'package:equatable/equatable.dart';

import '../../domain/entities/filters_effects_entities.dart';

abstract class FiltersEffectsEvent extends Equatable {
  const FiltersEffectsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFiltersEffects extends FiltersEffectsEvent {
  const LoadFiltersEffects({this.refreshAll = true});

  final bool refreshAll;

  @override
  List<Object?> get props => [refreshAll];
}

class LoadFiltersEffectsOverview extends FiltersEffectsEvent {
  const LoadFiltersEffectsOverview();
}

class LoadFiltersEffectsCatalog extends FiltersEffectsEvent {
  const LoadFiltersEffectsCatalog();
}

class LoadCameraFilters extends FiltersEffectsEvent {
  const LoadCameraFilters();
}

typedef LoadFilters = LoadCameraFilters;

class RefreshFilters extends FiltersEffectsEvent {
  const RefreshFilters();
}

class SearchFilters extends FiltersEffectsEvent {
  const SearchFilters(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends FiltersEffectsEvent {
  const FilterByCategory(this.categorySlug);

  final String? categorySlug;

  @override
  List<Object?> get props => [categorySlug];
}

class FilterByCategoryId extends FiltersEffectsEvent {
  const FilterByCategoryId(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class FilterByStatus extends FiltersEffectsEvent {
  const FilterByStatus(this.status);

  final FiltersEffectsStatusFilter status;

  @override
  List<Object?> get props => [status];
}

class LoadSingleFilter extends FiltersEffectsEvent {
  const LoadSingleFilter(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

typedef CreateFilter = CreateCameraFilterEvent;
typedef UpdateFilter = UpdateCameraFilterEvent;
typedef DeleteFilter = DeleteCameraFilterEvent;
typedef ActivateFilter = ActivateCameraFilterEvent;
typedef DeactivateFilter = DeactivateCameraFilterEvent;

class BulkUpdateFilters extends FiltersEffectsEvent {
  const BulkUpdateFilters(this.request);

  final BulkUpdateCameraFiltersRequest request;

  @override
  List<Object?> get props => [request];
}

class BulkActionFilters extends FiltersEffectsEvent {
  const BulkActionFilters(this.request);

  final BulkCameraFiltersRequest request;

  @override
  List<Object?> get props => [request];
}

class LoadCameraFilterCategories extends FiltersEffectsEvent {
  const LoadCameraFilterCategories();
}

class LoadCameraEffects extends FiltersEffectsEvent {
  const LoadCameraEffects();
}

class LoadCameraEffectCategories extends FiltersEffectsEvent {
  const LoadCameraEffectCategories();
}

class FiltersEffectsTabChanged extends FiltersEffectsEvent {
  const FiltersEffectsTabChanged(this.tab);

  final FiltersEffectsTab tab;

  @override
  List<Object?> get props => [tab];
}

class FiltersEffectsSearchChanged extends FiltersEffectsEvent {
  const FiltersEffectsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class FiltersEffectsFilterChanged extends FiltersEffectsEvent {
  const FiltersEffectsFilterChanged({
    this.status,
    this.renderType,
    this.clearRenderType = false,
    this.page,
  });

  final FiltersEffectsStatusFilter? status;
  final String? renderType;
  final bool clearRenderType;
  final int? page;

  @override
  List<Object?> get props => [status, renderType, clearRenderType, page];
}

class CreateCameraFilterEvent extends FiltersEffectsEvent {
  const CreateCameraFilterEvent(this.request);

  final CreateFilterRequest request;

  @override
  List<Object?> get props => [request];
}

class UpdateCameraFilterEvent extends FiltersEffectsEvent {
  const UpdateCameraFilterEvent(this.id, this.request);

  final String id;
  final UpdateFilterRequest request;

  @override
  List<Object?> get props => [id, request];
}

class DeleteCameraFilterEvent extends FiltersEffectsEvent {
  const DeleteCameraFilterEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ActivateCameraFilterEvent extends FiltersEffectsEvent {
  const ActivateCameraFilterEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class DeactivateCameraFilterEvent extends FiltersEffectsEvent {
  const DeactivateCameraFilterEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class CreateCameraFilterCategoryEvent extends FiltersEffectsEvent {
  const CreateCameraFilterCategoryEvent(this.request);

  final CreateCategoryRequest request;

  @override
  List<Object?> get props => [request];
}

class UpdateCameraFilterCategoryEvent extends FiltersEffectsEvent {
  const UpdateCameraFilterCategoryEvent(this.id, this.request);

  final String id;
  final UpdateCategoryRequest request;

  @override
  List<Object?> get props => [id, request];
}

class DeleteCameraFilterCategoryEvent extends FiltersEffectsEvent {
  const DeleteCameraFilterCategoryEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ReorderCameraFilterCategoriesEvent extends FiltersEffectsEvent {
  const ReorderCameraFilterCategoriesEvent(this.items);

  final List<CategoryReorderItem> items;

  @override
  List<Object?> get props => [items];
}

class AssignFiltersToCategoryEvent extends FiltersEffectsEvent {
  const AssignFiltersToCategoryEvent(this.categoryId, this.filters);

  final String categoryId;
  final List<FilterAssignmentItem> filters;

  @override
  List<Object?> get props => [categoryId, filters];
}

class CreateCameraEffectEvent extends FiltersEffectsEvent {
  const CreateCameraEffectEvent(this.request);

  final CreateEffectRequest request;

  @override
  List<Object?> get props => [request];
}

class UpdateCameraEffectEvent extends FiltersEffectsEvent {
  const UpdateCameraEffectEvent(this.id, this.request);

  final String id;
  final UpdateEffectRequest request;

  @override
  List<Object?> get props => [id, request];
}

class DeleteCameraEffectEvent extends FiltersEffectsEvent {
  const DeleteCameraEffectEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ActivateCameraEffectEvent extends FiltersEffectsEvent {
  const ActivateCameraEffectEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class DeactivateCameraEffectEvent extends FiltersEffectsEvent {
  const DeactivateCameraEffectEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class CreateCameraEffectCategoryEvent extends FiltersEffectsEvent {
  const CreateCameraEffectCategoryEvent(this.request);

  final CreateCategoryRequest request;

  @override
  List<Object?> get props => [request];
}

class UpdateCameraEffectCategoryEvent extends FiltersEffectsEvent {
  const UpdateCameraEffectCategoryEvent(this.id, this.request);

  final String id;
  final UpdateCategoryRequest request;

  @override
  List<Object?> get props => [id, request];
}

class DeleteCameraEffectCategoryEvent extends FiltersEffectsEvent {
  const DeleteCameraEffectCategoryEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ReorderCameraEffectCategoriesEvent extends FiltersEffectsEvent {
  const ReorderCameraEffectCategoriesEvent(this.items);

  final List<CategoryReorderItem> items;

  @override
  List<Object?> get props => [items];
}

class AssignEffectsToCategoryEvent extends FiltersEffectsEvent {
  const AssignEffectsToCategoryEvent(this.categoryId, this.effects);

  final String categoryId;
  final List<EffectAssignmentItem> effects;

  @override
  List<Object?> get props => [categoryId, effects];
}

class PublishFiltersEffectsCatalogEvent extends FiltersEffectsEvent {
  const PublishFiltersEffectsCatalogEvent(this.request);

  final PublishCatalogRequest request;

  @override
  List<Object?> get props => [request];
}

class SeedFiltersEffectsCatalogEvent extends FiltersEffectsEvent {
  const SeedFiltersEffectsCatalogEvent();
}

class ClearFiltersEffectsMessage extends FiltersEffectsEvent {
  const ClearFiltersEffectsMessage();
}

/// Surfaces a one-shot snackbar/dialog message on the management page.
class ShowFiltersEffectsMessage extends FiltersEffectsEvent {
  const ShowFiltersEffectsMessage(
    this.message, {
    this.isError = true,
  });

  final String message;
  final bool isError;

  @override
  List<Object?> get props => [message, isError];
}

class ToggleFilterSelectionEvent extends FiltersEffectsEvent {
  const ToggleFilterSelectionEvent(this.filterId);

  final String filterId;

  @override
  List<Object?> get props => [filterId];
}

class ToggleEffectSelectionEvent extends FiltersEffectsEvent {
  const ToggleEffectSelectionEvent(this.effectId);

  final String effectId;

  @override
  List<Object?> get props => [effectId];
}

class SelectAllVisibleFiltersEvent extends FiltersEffectsEvent {
  const SelectAllVisibleFiltersEvent();
}

class SelectAllVisibleEffectsEvent extends FiltersEffectsEvent {
  const SelectAllVisibleEffectsEvent();
}

class ClearFilterSelectionEvent extends FiltersEffectsEvent {
  const ClearFilterSelectionEvent();
}

class ClearEffectSelectionEvent extends FiltersEffectsEvent {
  const ClearEffectSelectionEvent();
}

class BulkDeleteSelectedFiltersEvent extends FiltersEffectsEvent {
  const BulkDeleteSelectedFiltersEvent();
}

class BulkDeleteSelectedEffectsEvent extends FiltersEffectsEvent {
  const BulkDeleteSelectedEffectsEvent();
}
