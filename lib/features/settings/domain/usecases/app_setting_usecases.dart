import '../entities/app_setting_entity.dart';
import '../entities/settings_admin_entities.dart';
import '../repositories/app_settings_repository.dart';

class ListAppSettingsUseCase {
  const ListAppSettingsUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<List<AppSettingEntity>> call() => _repository.listSettings();
}

class GetAppSettingUseCase {
  const GetAppSettingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppSettingEntity> call(String key) => _repository.getSetting(key);
}

class CreateAppSettingUseCase {
  const CreateAppSettingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppSettingEntity> call(AppSettingEntity setting) =>
      _repository.createSetting(setting);
}

class UpdateAppSettingUseCase {
  const UpdateAppSettingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppSettingEntity> call(AppSettingEntity setting) =>
      _repository.updateSetting(setting);
}

class DeleteAppSettingUseCase {
  const DeleteAppSettingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<void> call(String key) => _repository.deleteSetting(key);
}

class GetGroupedSettingsUseCase {
  const GetGroupedSettingsUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<SettingsGroupedResultEntity> call() =>
      _repository.getGroupedSettings();
}

class GetSettingsDefaultsUseCase {
  const GetSettingsDefaultsUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<SettingsDefaultsEntity> call() => _repository.getDefaults();
}

class SeedSettingsUseCase {
  const SeedSettingsUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<SettingsSeedResultEntity> call() => _repository.seedSettings();
}

class GetBrandingUseCase {
  const GetBrandingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppBrandingEntity> call() => _repository.getBranding();
}

class UpdateBrandingUseCase {
  const UpdateBrandingUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppBrandingEntity> call({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  }) {
    return _repository.updateBranding(
      appName: appName,
      tagline: tagline,
      supportEmail: supportEmail,
      logoUrl: logoUrl,
    );
  }
}

class ListCurrenciesUseCase {
  const ListCurrenciesUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<List<AppCurrencyEntity>> call() => _repository.listCurrencies();
}

class CreateCurrencyUseCase {
  const CreateCurrencyUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppCurrencyEntity> call(AppCurrencyEntity currency) =>
      _repository.createCurrency(currency);
}

class UpdateCurrencyUseCase {
  const UpdateCurrencyUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AppCurrencyEntity> call(AppCurrencyEntity currency) =>
      _repository.updateCurrency(currency);
}

class DeleteCurrencyUseCase {
  const DeleteCurrencyUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<void> call(String code) => _repository.deleteCurrency(code);
}

/// Parallel bootstrap used by the admin settings module.
class LoadAdminSettingsBundleUseCase {
  const LoadAdminSettingsBundleUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AdminSettingsBundle> call() async {
    final results = await Future.wait([
      _repository.getGroupedSettings(),
      _repository.getDefaults(),
      _repository.getBranding(),
      _repository.listCurrencies(),
    ]);

    return AdminSettingsBundle(
      grouped: results[0] as SettingsGroupedResultEntity,
      defaults: results[1] as SettingsDefaultsEntity,
      branding: results[2] as AppBrandingEntity,
      currencies: results[3] as List<AppCurrencyEntity>,
    );
  }
}

class AdminSettingsBundle {
  const AdminSettingsBundle({
    required this.grouped,
    required this.defaults,
    required this.branding,
    required this.currencies,
  });

  final SettingsGroupedResultEntity grouped;
  final SettingsDefaultsEntity defaults;
  final AppBrandingEntity branding;
  final List<AppCurrencyEntity> currencies;
}
