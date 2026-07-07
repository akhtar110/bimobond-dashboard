import '../entities/economy_setting_entity.dart';

abstract class EconomySettingsRepository {
  Future<EconomySettingEntity> getSetting(String key);
  Future<EconomySettingEntity> updateSetting(String key, String value);
}
