import '../../domain/entities/app_setting_entity.dart';

class AppSettingModel extends AppSettingEntity {
  const AppSettingModel({
    required super.key,
    required super.value,
    super.id,
    super.description,
    super.type,
    super.category,
    super.label,
    super.sortOrder,
    super.isPublic,
    super.createdAt,
    super.updatedAt,
  });

  factory AppSettingModel.fromEntity(AppSettingEntity entity) {
    return AppSettingModel(
      id: entity.id,
      key: entity.key,
      value: entity.value,
      description: entity.description,
      type: entity.type,
      category: entity.category,
      label: entity.label,
      sortOrder: entity.sortOrder,
      isPublic: entity.isPublic,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      id: json['id']?.toString(),
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'STRING',
      category: json['category']?.toString(),
      label: json['label']?.toString(),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      isPublic: json['isPublic'] == true ||
          json['isPublic']?.toString().toLowerCase() == 'true',
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'key': key,
        'value': value,
        if (type.isNotEmpty) 'type': type,
        if (category != null && category!.isNotEmpty) 'category': category,
        if (label != null && label!.isNotEmpty) 'label': label,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'sortOrder': sortOrder,
        'isPublic': isPublic,
      };

  Map<String, dynamic> toUpdateJson() => {
        'value': value,
        if (type.isNotEmpty) 'type': type,
        if (category != null) 'category': category,
        if (label != null) 'label': label,
        if (description != null) 'description': description,
        'sortOrder': sortOrder,
        'isPublic': isPublic,
      };

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
