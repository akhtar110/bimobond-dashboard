import '../../domain/entities/filters_effects_entities.dart';

/// Client-side list for Filters tab when a category chip is selected.
List<CameraFilterEntity> filtersForDisplay({
  required List<CameraFilterEntity> pagedFilters,
  required List<CameraFilterCategoryEntity> filterCategories,
  required FiltersEffectsListQuery query,
  String? selectedCategoryId,
}) {
  if (selectedCategoryId == null) return pagedFilters;

  CameraFilterCategoryEntity? category;
  for (final c in filterCategories) {
    if (c.id == selectedCategoryId) {
      category = c;
      break;
    }
  }
  return _applyFilterQueryLocally(
    category?.filters ?? const <CameraFilterEntity>[],
    query,
  ).toList();
}

/// Client-side list for Effects tab when a category chip is selected.
List<CameraEffectEntity> effectsForDisplay({
  required List<CameraEffectEntity> pagedEffects,
  required List<CameraEffectCategoryEntity> effectCategories,
  required FiltersEffectsListQuery query,
  String? selectedCategoryId,
}) {
  if (selectedCategoryId == null) return pagedEffects;

  CameraEffectCategoryEntity? category;
  for (final c in effectCategories) {
    if (c.id == selectedCategoryId) {
      category = c;
      break;
    }
  }
  return _applyEffectQueryLocally(
    category?.effects ?? const <CameraEffectEntity>[],
    query,
  ).toList();
}

int feAppliedFilterCount({
  required FiltersEffectsListQuery query,
  required bool includeRenderType,
}) {
  var count = 0;
  if (query.status != FiltersEffectsStatusFilter.active) count++;
  if (includeRenderType &&
      query.renderType != null &&
      query.renderType!.trim().isNotEmpty) {
    count++;
  }
  return count;
}

Iterable<CameraFilterEntity> _applyFilterQueryLocally(
  Iterable<CameraFilterEntity> list,
  FiltersEffectsListQuery query,
) {
  var result = list;
  final search = query.search.trim().toLowerCase();
  if (search.isNotEmpty) {
    result = result.where((f) {
      return f.displayLabel.toLowerCase().contains(search) ||
          f.slug.toLowerCase().contains(search) ||
          (f.labelKey?.toLowerCase().contains(search) ?? false);
    });
  }
  switch (query.status) {
    case FiltersEffectsStatusFilter.active:
      result = result.where((f) => f.isActive);
    case FiltersEffectsStatusFilter.inactive:
      result = result.where((f) => !f.isActive);
    case FiltersEffectsStatusFilter.all:
      break;
  }
  final renderType = query.renderType?.trim();
  if (renderType != null && renderType.isNotEmpty) {
    final normalized = CameraFilterRenderTypeApi.fromResponse(renderType);
    result = result.where(
      (f) => CameraFilterRenderTypeApi.fromResponse(f.renderType) == normalized,
    );
  }
  return result;
}

Iterable<CameraEffectEntity> _applyEffectQueryLocally(
  Iterable<CameraEffectEntity> list,
  FiltersEffectsListQuery query,
) {
  var result = list;
  final search = query.search.trim().toLowerCase();
  if (search.isNotEmpty) {
    result = result.where((e) {
      return e.displayLabel.toLowerCase().contains(search) ||
          e.slug.toLowerCase().contains(search) ||
          (e.labelKey?.toLowerCase().contains(search) ?? false);
    });
  }
  switch (query.status) {
    case FiltersEffectsStatusFilter.active:
      result = result.where((e) => e.isActive);
    case FiltersEffectsStatusFilter.inactive:
      result = result.where((e) => !e.isActive);
    case FiltersEffectsStatusFilter.all:
      break;
  }
  final renderType = query.renderType?.trim();
  if (renderType != null && renderType.isNotEmpty) {
    final normalized = CameraEffectRenderTypeApi.fromResponse(renderType);
    result = result.where(
      (e) => CameraEffectRenderTypeApi.fromResponse(e.renderType) == normalized,
    );
  }
  return result;
}
