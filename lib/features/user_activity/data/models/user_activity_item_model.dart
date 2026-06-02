import '../../domain/entities/user_activity_item_entity.dart';

class UserActivityItemModel extends UserActivityItemEntity {
  const UserActivityItemModel({
    required super.id,
    required super.type,
    required super.createdAt,
    required super.details,
  });

  factory UserActivityItemModel.fromJson(Map<String, dynamic> json) {
    return UserActivityItemModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      createdAt: _date(json['createdAt']),
      details: json['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['details'] as Map<String, dynamic>)
          : const {},
    );
  }

  static DateTime _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
