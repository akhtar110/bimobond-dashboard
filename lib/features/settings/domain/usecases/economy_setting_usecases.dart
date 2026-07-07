import '../entities/economy_setting_entity.dart';
import '../repositories/economy_settings_repository.dart';

class GetEconomySettingUseCase {
  const GetEconomySettingUseCase(this._repository);
  final EconomySettingsRepository _repository;

  Future<EconomySettingEntity> call(String key) => _repository.getSetting(key);
}

class UpdateEconomySettingUseCase {
  const UpdateEconomySettingUseCase(this._repository);
  final EconomySettingsRepository _repository;

  Future<EconomySettingEntity> call(String key, String value) =>
      _repository.updateSetting(key, value);
}
