import '../../domain/entities/economy_setting_entity.dart';
import '../../domain/repositories/economy_settings_repository.dart';
import '../datasources/economy_settings_remote_datasource.dart';

class EconomySettingsRepositoryImpl implements EconomySettingsRepository {
  const EconomySettingsRepositoryImpl(this._remote);
  final EconomySettingsRemoteDataSource _remote;

  @override
  Future<EconomySettingEntity> getSetting(String key) => _remote.getSetting(key);

  @override
  Future<EconomySettingEntity> updateSetting(String key, String value) =>
      _remote.updateSetting(key, value);
}
