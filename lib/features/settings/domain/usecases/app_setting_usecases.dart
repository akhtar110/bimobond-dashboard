import 'dart:typed_data';

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

class UploadBrandingLogoUseCase {
  const UploadBrandingLogoUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<String> call({
    required Uint8List bytes,
    required String filename,
  }) {
    return _repository.uploadBrandingLogo(bytes, filename);
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
///
/// Each request is isolated so a currencies-only (or partial) permission
/// set can still load what the caller is allowed to see.
class LoadAdminSettingsBundleUseCase {
  const LoadAdminSettingsBundleUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<AdminSettingsBundle> call() async {
    SettingsGroupedResultEntity? grouped;
    SettingsDefaultsEntity? defaults;
    AppBrandingEntity? branding;
    List<AppCurrencyEntity> currencies = const [];
    var currenciesLoaded = false;
    Object? firstError;

    Future<void> run(Future<void> Function() fn) async {
      try {
        await fn();
      } catch (e) {
        firstError ??= e;
      }
    }

    await Future.wait([
      run(() async {
        grouped = await _repository.getGroupedSettings();
      }),
      run(() async {
        defaults = await _repository.getDefaults();
      }),
      run(() async {
        branding = await _repository.getBranding();
      }),
      run(() async {
        currencies = await _repository.listCurrencies();
        currenciesLoaded = true;
      }),
    ]);

    final hasAny = grouped != null ||
        defaults != null ||
        branding != null ||
        currenciesLoaded;
    if (!hasAny && firstError != null) {
      throw firstError!;
    }

    return AdminSettingsBundle(
      grouped: grouped ?? const SettingsGroupedResultEntity(),
      defaults: defaults ?? const SettingsDefaultsEntity(),
      branding: branding ??
          const AppBrandingEntity(
            id: '',
            appName: 'DCC',
          ),
      currencies: currencies,
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
