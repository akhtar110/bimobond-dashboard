import '../../domain/entities/app_setting_entity.dart';
import '../../domain/entities/settings_admin_entities.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/app_settings_remote_datasource.dart';
import '../models/app_setting_model.dart';
import '../models/settings_admin_models.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this._remote);
  final AppSettingsRemoteDataSource _remote;

  @override
  Future<List<AppSettingEntity>> listSettings() => _remote.listSettings();

  @override
  Future<AppSettingEntity> getSetting(String key) => _remote.getSetting(key);

  @override
  Future<AppSettingEntity> createSetting(AppSettingEntity setting) {
    return _remote.createSetting(AppSettingModel.fromEntity(setting));
  }

  @override
  Future<AppSettingEntity> updateSetting(AppSettingEntity setting) {
    return _remote.updateSetting(AppSettingModel.fromEntity(setting));
  }

  @override
  Future<void> deleteSetting(String key) => _remote.deleteSetting(key);

  @override
  Future<SettingsGroupedResultEntity> getGroupedSettings() =>
      _remote.getGroupedSettings();

  @override
  Future<SettingsDefaultsEntity> getDefaults() => _remote.getDefaults();

  @override
  Future<SettingsSeedResultEntity> seedSettings() => _remote.seedSettings();

  @override
  Future<AppBrandingEntity> getBranding() => _remote.getBranding();

  @override
  Future<AppBrandingEntity> updateBranding({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  }) {
    return _remote.updateBranding(
      appName: appName,
      tagline: tagline,
      supportEmail: supportEmail,
      logoUrl: logoUrl,
    );
  }

  @override
  Future<List<AppCurrencyEntity>> listCurrencies() => _remote.listCurrencies();

  @override
  Future<AppCurrencyEntity> createCurrency(AppCurrencyEntity currency) {
    return _remote.createCurrency(
      AppCurrencyModel(
        id: currency.id,
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
        isDefault: currency.isDefault,
        isActive: currency.isActive,
        coinsPerUnit: currency.coinsPerUnit,
        createdAt: currency.createdAt,
        updatedAt: currency.updatedAt,
      ),
    );
  }

  @override
  Future<AppCurrencyEntity> updateCurrency(AppCurrencyEntity currency) {
    return _remote.updateCurrency(
      AppCurrencyModel(
        id: currency.id,
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
        isDefault: currency.isDefault,
        isActive: currency.isActive,
        coinsPerUnit: currency.coinsPerUnit,
        createdAt: currency.createdAt,
        updatedAt: currency.updatedAt,
      ),
    );
  }

  @override
  Future<void> deleteCurrency(String code) => _remote.deleteCurrency(code);
}
