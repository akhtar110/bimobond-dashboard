import '../../domain/entities/post_applied_catalog_ref.dart';

PostAppliedCatalogRef? parsePostAppliedFilter(Map<String, dynamic> json) {
  return _parseAppliedRef(
    json: json,
    nestedKeys: const ['filter', 'cameraFilter', 'appliedFilter'],
    idKeys: const ['filterId'],
    slugKeys: const ['filterSlug', 'filterName'],
    labelKeys: const ['filterName', 'filterLabel', 'filterTitle'],
    stringKey: 'filter',
  );
}

PostAppliedCatalogRef? parsePostAppliedEffect(Map<String, dynamic> json) {
  return _parseAppliedRef(
    json: json,
    nestedKeys: const ['effect', 'cameraEffect', 'appliedEffect'],
    idKeys: const ['effectId'],
    slugKeys: const ['effectSlug', 'effectName'],
    labelKeys: const ['effectName', 'effectLabel', 'effectTitle'],
    stringKey: 'effect',
  );
}

String? readManagedPostFilterCatalogId(Map<String, dynamic> json) {
  return parsePostAppliedFilter(json)?.catalogId;
}

String? readManagedPostEffectCatalogId(Map<String, dynamic> json) {
  return parsePostAppliedEffect(json)?.catalogId;
}

PostAppliedCatalogRef? _parseAppliedRef({
  required Map<String, dynamic> json,
  required List<String> nestedKeys,
  required List<String> idKeys,
  required List<String> slugKeys,
  required List<String> labelKeys,
  required String stringKey,
}) {
  String? catalogId;
  String? slug;
  String? displayName;
  String? thumbnailUrl;
  String? emoji;

  for (final key in idKeys) {
    catalogId ??= _readCatalogId(json[key]);
  }
  for (final key in slugKeys) {
    slug ??= _readText(json[key]);
  }
  for (final key in labelKeys) {
    displayName ??= _readText(json[key]);
  }

  final nested = _firstMap(json, nestedKeys);
  if (nested != null) {
    catalogId ??= _readCatalogId(nested['filterId']) ??
        _readCatalogId(nested['effectId']) ??
        _readCatalogId(nested['id']) ??
        _readCatalogId(nested['_id']);
    slug ??= _readText(nested['slug']);
    displayName ??= _readText(nested['label']) ??
        _readText(nested['customLabel']) ??
        _readText(nested['name']) ??
        _readText(nested['title']);
    thumbnailUrl ??= _readText(nested['thumbnailUrl']) ??
        _readText(nested['thumbnail']);
    emoji ??= _readText(nested['emoji']);
    for (final key in slugKeys) {
      slug ??= _readText(nested[key]);
    }
    for (final key in labelKeys) {
      displayName ??= _readText(nested[key]);
    }
  }

  final rawString = json[stringKey];
  if (rawString is String && rawString.trim().isNotEmpty) {
    final value = rawString.trim();
    slug ??= value;
    displayName ??= value;
    catalogId ??= _looksLikeCatalogResourceId(value) ? value : null;
  }

  // When backend stores the slug in filterId/effectId, keep slug for lookup.
  for (final key in idKeys) {
    final raw = _readText(json[key]);
    if (raw != null && !_looksLikeCatalogResourceId(raw)) {
      slug ??= raw;
      displayName ??= raw;
    }
  }

  if (catalogId == null &&
      slug == null &&
      displayName == null &&
      thumbnailUrl == null &&
      emoji == null) {
    return null;
  }

  return PostAppliedCatalogRef(
    catalogId: catalogId,
    slug: slug,
    displayName: displayName ?? slug,
    thumbnailUrl: thumbnailUrl,
    emoji: emoji,
  );
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final raw = json[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
  }
  return null;
}

String? _readText(dynamic raw) {
  if (raw == null) return null;
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}

String? _readCatalogId(dynamic raw) {
  final value = _readText(raw);
  if (value == null) return null;
  return _looksLikeCatalogResourceId(value) ? value : null;
}

bool _looksLikeCatalogResourceId(String value) {
  if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(value)) return true;
  if (RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value)) {
    return true;
  }
  if (value.length >= 20 && RegExp(r'^[a-z0-9]+$').hasMatch(value)) {
    return true;
  }
  return false;
}
