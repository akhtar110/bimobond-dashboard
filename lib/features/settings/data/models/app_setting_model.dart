import '../../domain/entities/app_setting_entity.dart';

class AppSettingModel extends AppSettingEntity {
  const AppSettingModel({
    required super.key,
    required super.value,
    super.description,
  });

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'key': key,
        'value': value,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };

  Map<String, dynamic> toUpdateJson() => {
        'value': value,
        if (description != null) 'description': description,
      };
}
