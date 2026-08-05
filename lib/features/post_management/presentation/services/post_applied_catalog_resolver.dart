import '../../../filters_effects/domain/entities/filters_effects_entities.dart';
import '../../../filters_effects/domain/usecases/filters_effects_usecases.dart';
import '../../domain/entities/post_applied_catalog_ref.dart';

abstract final class PostAppliedCatalogResolver {
  static Future<CameraFilterEntity?> resolveFilter({
    required PostAppliedCatalogRef ref,
    required GetCameraFilterUseCase getById,
    required GetCameraFiltersUseCase listFilters,
  }) async {
    final catalogId = ref.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      try {
        return await getById(catalogId);
      } catch (_) {}
    }

    final searchTerm = _searchTerm(ref);
    if (searchTerm != null) {
      try {
        final page = await listFilters(
          FiltersEffectsListQuery(search: searchTerm, pageSize: 50),
        );
        final match = _pickFilter(page.data, ref);
        if (match != null) return match;
      } catch (_) {}
    }

    return ref.hasData ? _fallbackFilter(ref) : null;
  }

  static Future<CameraEffectEntity?> resolveEffect({
    required PostAppliedCatalogRef ref,
    required GetCameraEffectUseCase getById,
    required GetCameraEffectsUseCase listEffects,
  }) async {
    final catalogId = ref.catalogId?.trim();
    if (catalogId != null && catalogId.isNotEmpty) {
      try {
        return await getById(catalogId);
      } catch (_) {}
    }

    final searchTerm = _searchTerm(ref);
    if (searchTerm != null) {
      try {
        final page = await listEffects(
          FiltersEffectsListQuery(search: searchTerm, pageSize: 50),
        );
        final match = _pickEffect(page.data, ref);
        if (match != null) return match;
      } catch (_) {}
    }

    return ref.hasData ? _fallbackEffect(ref) : null;
  }

  static String? _searchTerm(PostAppliedCatalogRef ref) {
    if (ref.slug?.trim().isNotEmpty == true) return ref.slug!.trim();
    if (ref.displayName?.trim().isNotEmpty == true) return ref.displayName!.trim();
    return null;
  }

  static CameraFilterEntity? _pickFilter(
    List<CameraFilterEntity> filters,
    PostAppliedCatalogRef ref,
  ) {
    if (filters.isEmpty) return null;

    final slug = ref.slug?.trim().toLowerCase();
    if (slug != null && slug.isNotEmpty) {
      for (final filter in filters) {
        if (filter.slug.toLowerCase() == slug) return filter;
        if (filter.id.toLowerCase() == slug) return filter;
      }
    }

    final label = ref.displayName?.trim().toLowerCase();
    if (label != null && label.isNotEmpty) {
      for (final filter in filters) {
        if (filter.displayLabel.toLowerCase() == label) return filter;
        if (filter.label.toLowerCase() == label) return filter;
      }
    }

    return filters.length == 1 ? filters.first : null;
  }

  static CameraEffectEntity? _pickEffect(
    List<CameraEffectEntity> effects,
    PostAppliedCatalogRef ref,
  ) {
    if (effects.isEmpty) return null;

    final slug = ref.slug?.trim().toLowerCase();
    if (slug != null && slug.isNotEmpty) {
      for (final effect in effects) {
        if (effect.slug.toLowerCase() == slug) return effect;
        if (effect.id.toLowerCase() == slug) return effect;
      }
    }

    final label = ref.displayName?.trim().toLowerCase();
    if (label != null && label.isNotEmpty) {
      for (final effect in effects) {
        if (effect.displayLabel.toLowerCase() == label) return effect;
        if (effect.label.toLowerCase() == label) return effect;
      }
    }

    return effects.length == 1 ? effects.first : null;
  }

  static CameraFilterEntity _fallbackFilter(PostAppliedCatalogRef ref) {
    return CameraFilterEntity(
      id: ref.editorCatalogId ?? ref.slug ?? ref.primaryLabel,
      slug: ref.slug ?? ref.primaryLabel,
      label: ref.primaryLabel,
      emoji: ref.emoji,
      thumbnailUrl: ref.thumbnailUrl,
    );
  }

  static CameraEffectEntity _fallbackEffect(PostAppliedCatalogRef ref) {
    return CameraEffectEntity(
      id: ref.editorCatalogId ?? ref.slug ?? ref.primaryLabel,
      slug: ref.slug ?? ref.primaryLabel,
      renderType: 'sticker',
      label: ref.primaryLabel,
      emoji: ref.emoji,
      thumbnailUrl: ref.thumbnailUrl,
    );
  }
}
