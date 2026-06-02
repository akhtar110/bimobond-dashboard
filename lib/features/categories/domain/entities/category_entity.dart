class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// ─── DTOs for CRUD operations ─────────────────────────────────────────────────

class CreateCategoryData {
  const CreateCategoryData({
    required this.name,
    this.description,
    this.isActive = true,
    this.order = 0,
  });

  final String name;
  final String? description;
  final bool isActive;
  final int order;
}

class UpdateCategoryData {
  const UpdateCategoryData({
    this.name,
    this.description,
    this.isActive,
    this.order,
  });

  final String? name;
  final String? description;
  final bool? isActive;
  final int? order;
}
