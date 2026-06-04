import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    required super.isActive,
    super.order = 0,
    required super.createdAt,
    required super.updatedAt,
    super.parentId,
    super.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Parse nested children list recursively.
    final rawChildren = json['children'];
    final List<CategoryEntity> children = rawChildren is List
        ? rawChildren
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : const [];

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      parentId: json['parentId'] as String?,
      children: children,
    );
  }

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
