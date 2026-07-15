import '../../domain/entities/user_interest_entities.dart';
import 'interest_category_model.dart';

class UserInterestModel extends UserInterestEntity {
  const UserInterestModel({
    super.userId,
    required super.categoryId,
    required super.preference,
    required super.source,
    required super.createdAt,
    required super.updatedAt,
    required super.category,
  });

  factory UserInterestModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return UserInterestModel(
      userId: json['userId']?.toString(),
      categoryId: json['categoryId']?.toString() ??
          (categoryJson is Map ? categoryJson['id']?.toString() : null) ??
          '',
      preference: userInterestPreferenceFromApi(json['preference']?.toString()),
      source: userInterestSourceFromApi(json['source']?.toString()),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ??
          _date(json['createdAt']) ??
          DateTime.now(),
      category: InterestCategoryModel.fromJson(
        categoryJson is Map<String, dynamic>
            ? categoryJson
            : categoryJson is Map
                ? Map<String, dynamic>.from(categoryJson)
                : null,
      ),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
