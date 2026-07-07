import '../entities/app_setting_entity.dart';

abstract class AppSettingsRepository {
  Future<List<AppSettingEntity>> listSettings();
  Future<AppSettingEntity> createSetting(AppSettingEntity setting);
  Future<AppSettingEntity> updateSetting(AppSettingEntity setting);
  Future<void> deleteSetting(String key);
}
