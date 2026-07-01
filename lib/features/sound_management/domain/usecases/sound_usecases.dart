import '../entities/sound_entities.dart';
import '../repositories/sound_management_repository.dart';

class GetSoundOverviewUseCase {
  const GetSoundOverviewUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundOverviewEntity> call() => _repository.getOverview();
}

class GetSoundsUseCase {
  const GetSoundsUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<PaginatedSoundsEntity> call(SoundsQuery query) =>
      _repository.getSounds(query);
}

class CreateSoundUseCase {
  const CreateSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundEntity> call(CreateSoundData data) => _repository.createSound(data);
}

class UploadSoundUseCase {
  const UploadSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundEntity> call(UploadSoundData data) => _repository.uploadSound(data);
}

class UpdateSoundUseCase {
  const UpdateSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundEntity> call(String soundId, UpdateSoundData data) =>
      _repository.updateSound(soundId, data);
}

class ActivateSoundUseCase {
  const ActivateSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundEntity> call(String soundId) => _repository.activateSound(soundId);
}

class DeactivateSoundUseCase {
  const DeactivateSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<SoundEntity> call(String soundId) =>
      _repository.deactivateSound(soundId);
}

class DeleteSoundUseCase {
  const DeleteSoundUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<void> call(String soundId) => _repository.deleteSound(soundId);
}

class BulkSoundActionUseCase {
  const BulkSoundActionUseCase(this._repository);
  final SoundManagementRepository _repository;

  Future<BulkSoundActionResultEntity> call(BulkSoundActionRequest request) =>
      _repository.bulkAction(request);
}
