import '../../domain/entities/economy_setting_entity.dart';

class EconomySettingModel extends EconomySettingEntity {
  const EconomySettingModel({
    required super.key,
    required super.value,
  });

  factory EconomySettingModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackKey,
  }) {
    return EconomySettingModel(
      key: json['key']?.toString() ?? fallbackKey ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}
