import 'dart:typed_data';

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
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

  /// Remote icon path or URL (`iconUrl` from API).
  final String? iconUrl;

  final bool isActive;

  /// Display sort order (ascending). Lower values appear first.
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

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? iconUrl,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentId,
    List<CategoryEntity>? children,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
    );
  }
}

// ─── DTOs for CRUD operations ─────────────────────────────────────────────────

class CreateCategoryData {
  const CreateCategoryData({
    required this.name,
    this.description,
    this.iconUrl,
    this.iconBytes,
    this.iconFilename,
    this.isActive = true,
    this.order = 0,
    this.parentId,
  });

  final String name;
  final String? description;
  final String? iconUrl;
  final Uint8List? iconBytes;
  final String? iconFilename;
  final bool isActive;
  final int order;

  /// `null` → root category; non-null → subcategory under that parent.
  final String? parentId;
}

class UpdateCategoryData {
  const UpdateCategoryData({
    this.name,
    this.description,
    this.iconUrl,
    this.setIconUrl = false,
    this.iconBytes,
    this.iconFilename,
    this.isActive,
    this.order,
    this.parentId,
    this.setParentId = false,
  });

  final String? name;
  final String? description;
  final String? iconUrl;

  /// When `true`, include `iconUrl` in PATCH (use `null` to clear icon).
  final bool setIconUrl;
  final Uint8List? iconBytes;
  final String? iconFilename;
  final bool? isActive;
  final int? order;

  /// New parent UUID, or `null` to promote to root.
  /// Only included in the API payload when [setParentId] is `true`.
  final String? parentId;

  /// Set to `true` to explicitly include `parentId` in the PATCH payload
  /// (even when the value is `null` — which clears the parent).
  final bool setParentId;
}
