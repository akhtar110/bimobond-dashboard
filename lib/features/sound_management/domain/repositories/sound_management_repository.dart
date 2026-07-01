import '../entities/sound_entities.dart';

abstract class SoundManagementRepository {
  Future<SoundOverviewEntity> getOverview();
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query);
  Future<SoundEntity> createSound(CreateSoundData data);
  Future<SoundEntity> uploadSound(UploadSoundData data);
  Future<SoundEntity> updateSound(String soundId, UpdateSoundData data);
  Future<SoundEntity> activateSound(String soundId);
  Future<SoundEntity> deactivateSound(String soundId);
  Future<void> deleteSound(String soundId);
  Future<BulkSoundActionResultEntity> bulkAction(BulkSoundActionRequest request);
}
