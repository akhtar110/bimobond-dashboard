import '../../../post_management/data/utils/managed_post_location_hydration.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../entities/post_filters.dart';

String _normalizePlaceLabel(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Whether two location labels refer to the same place for filtering.
///
/// Matches the displayed place name exactly (case-insensitive), e.g.
/// "Jeddah, Saudi Arabia" — no radius or city-only fallback.
bool locationDisplayLabelsMatch(String filter, String postLabel) {
  final query = _normalizePlaceLabel(filter);
  final label = _normalizePlaceLabel(postLabel);
  if (query.isEmpty || label.isEmpty) return false;
  return query == label;
}

/// Whether [post] matches the active place-name location filter.
bool postMatchesLocationFilter(ManagedPostEntity post, PostFilters filters) {
  if (!filters.hasLocationFilter) return true;

  final query = filters.locationCity?.trim();
  if (query == null || query.isEmpty) return true;

  final label = managedPostListLocationLabel(post)?.trim();
  if (label == null || label.isEmpty) return false;

  return locationDisplayLabelsMatch(query, label);
}
