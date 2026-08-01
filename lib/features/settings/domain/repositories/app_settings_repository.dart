import 'dart:typed_data';

import '../entities/app_setting_entity.dart';
import '../entities/settings_admin_entities.dart';

abstract class AppSettingsRepository {
  Future<List<AppSettingEntity>> listSettings();
  Future<AppSettingEntity> getSetting(String key);
  Future<AppSettingEntity> createSetting(AppSettingEntity setting);
  Future<AppSettingEntity> updateSetting(AppSettingEntity setting);
  Future<void> deleteSetting(String key);

  Future<SettingsGroupedResultEntity> getGroupedSettings();
  Future<SettingsDefaultsEntity> getDefaults();
  Future<SettingsSeedResultEntity> seedSettings();

  Future<AppBrandingEntity> getBranding();
  Future<AppBrandingEntity> updateBranding({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  });

  Future<String> uploadBrandingLogo(Uint8List bytes, String filename);

  Future<List<AppCurrencyEntity>> listCurrencies();
  Future<AppCurrencyEntity> createCurrency(AppCurrencyEntity currency);
  Future<AppCurrencyEntity> updateCurrency(AppCurrencyEntity currency);
  Future<void> deleteCurrency(String code);
}
