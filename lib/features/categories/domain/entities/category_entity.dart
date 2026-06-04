class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.isActive,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;

  /// Auto-managed by backend — read-only in the admin UI.
  final int order;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// `null` for root categories; UUID of parent for subcategories.
  final String? parentId;

  /// Direct children (subcategories). Populated by the API tree response or
  /// by grouping logic in the BLoC/UI.
  final List<CategoryEntity> children;

  bool get isRoot => parentId == null;
  bool get hasChildren => children.isNotEmpty;
}

// ─── DTOs for CRUD operations ─────────────────────────────────────────────────

class CreateCategoryData {
  const CreateCategoryData({
    required this.name,
    this.description,
    this.isActive = true,
    this.parentId,
  });

  final String name;
  final String? description;
  final bool isActive;

  /// `null` → root category; non-null → subcategory under that parent.
  final String? parentId;
}

class UpdateCategoryData {
  const UpdateCategoryData({
    this.name,
    this.description,
    this.isActive,
    this.parentId,
    this.setParentId = false,
  });

  final String? name;
  final String? description;
  final bool? isActive;

  /// New parent UUID, or `null` to promote to root.
  /// Only included in the API payload when [setParentId] is `true`.
  final String? parentId;

  /// Set to `true` to explicitly include `parentId` in the PATCH payload
  /// (even when the value is `null` — which clears the parent).
  final bool setParentId;
}
