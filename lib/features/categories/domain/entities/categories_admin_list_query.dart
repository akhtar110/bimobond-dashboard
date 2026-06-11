/// Mirrors backend `CategoriesAdminListQueryDto` for GET /categories/admin/all.
class CategoriesAdminListQuery {
  const CategoriesAdminListQuery({
    this.search,
    this.includeInactive,
    this.parentId,
    this.flat,
    this.isActive,
    this.isMain,
  });

  final String? search;
  final bool? includeInactive;
  final String? parentId;
  final bool? flat;
  final bool? isActive;
  final bool? isMain;

  bool get isDefault =>
      (search == null || search!.isEmpty) &&
      includeInactive == null &&
      parentId == null &&
      flat == null &&
      isActive == null &&
      isMain == null;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['search'] = trimmed;
    }
    if (includeInactive != null) {
      params['includeInactive'] = includeInactive.toString();
    }
    if (parentId != null) {
      params['parentId'] = parentId;
    }
    if (flat != null) {
      params['flat'] = flat.toString();
    }
    if (isActive != null) {
      params['isActive'] = isActive.toString();
    }
    if (isMain != null) {
      params['isMain'] = isMain.toString();
    }
    return params;
  }
}
