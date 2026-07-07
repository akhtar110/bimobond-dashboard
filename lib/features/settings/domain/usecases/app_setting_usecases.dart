import '../entities/app_setting_entity.dart';
import '../repositories/app_settings_repository.dart';

class ListAppSettingsUseCase {
  const ListAppSettingsUseCase(this._repository);
  final AppSettingsRepository _repository;

  Future<List<AppSettingEntity>> call() => _repository.listSettings();
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
