import '../../domain/entities/app_setting_entity.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/app_settings_remote_datasource.dart';
import '../models/app_setting_model.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this._remote);
  final AppSettingsRemoteDataSource _remote;

  @override
  Future<List<AppSettingEntity>> listSettings() => _remote.listSettings();

  @override
  Future<AppSettingEntity> createSetting(AppSettingEntity setting) {
    return _remote.createSetting(
      AppSettingModel(
        key: setting.key,
        value: setting.value,
        description: setting.description,
      ),
    );
  }

  @override
  Future<AppSettingEntity> updateSetting(AppSettingEntity setting) {
    return _remote.updateSetting(
      AppSettingModel(
        key: setting.key,
        value: setting.value,
        description: setting.description,
      ),
    );
  }

  @override
  Future<void> deleteSetting(String key) => _remote.deleteSetting(key);
}
