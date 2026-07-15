import '../../domain/entities/user_interest_entities.dart';

class InterestCategoryModel extends InterestCategoryEntity {
  const InterestCategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.iconUrl,
    super.parentId,
    super.isActive,
    super.order,
  });

  factory InterestCategoryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InterestCategoryModel(
        id: '',
        name: 'Unknown',
        slug: 'unknown',
      );
    }
    return InterestCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      parentId: json['parentId']?.toString(),
      isActive: json['isActive'] != false,
      order: _int(json['order']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
