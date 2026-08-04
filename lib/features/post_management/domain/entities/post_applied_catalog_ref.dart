/// Snapshot of a camera-studio filter/effect applied to a post.
class PostAppliedCatalogRef {
  const PostAppliedCatalogRef({
    this.catalogId,
    this.slug,
    this.displayName,
    this.thumbnailUrl,
    this.emoji,
  });

  /// Camera-studio catalog UUID (for admin GET by id).
  final String? catalogId;

  /// Catalog slug stored on the post (e.g. `sunsetFilter`).
  final String? slug;

  /// Human-readable label / filter name shown to admins.
  final String? displayName;
  final String? thumbnailUrl;
  final String? emoji;

  bool get hasData =>
      _nonEmpty(catalogId) ||
      _nonEmpty(slug) ||
      _nonEmpty(displayName) ||
      _nonEmpty(thumbnailUrl) ||
      _nonEmpty(emoji);

  String get primaryLabel {
    if (_nonEmpty(displayName)) return displayName!.trim();
    if (_nonEmpty(slug)) return _humanizeSlug(slug!.trim());
    if (_nonEmpty(catalogId)) return catalogId!.trim();
    return '';
  }

  /// Best id to open the catalog editor, when available.
  String? get editorCatalogId {
    if (_nonEmpty(catalogId)) return catalogId!.trim();
    return null;
  }

  static bool _nonEmpty(String? value) => value?.trim().isNotEmpty == true;

  static String _humanizeSlug(String slug) {
    if (slug.isEmpty) return slug;
    final spaced = slug.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    if (spaced == slug) {
      return slug.replaceAll('_', ' ').replaceAll('-', ' ');
    }
    return spaced;
  }
}
