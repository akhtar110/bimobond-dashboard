import '../../domain/entities/sound_entities.dart';
import '../../domain/repositories/sound_management_repository.dart';
import '../datasources/sound_management_remote_datasource.dart';

class SoundManagementRepositoryImpl implements SoundManagementRepository {
  const SoundManagementRepositoryImpl(this._remote);
  final SoundManagementRemoteDataSource _remote;

  @override
  Future<SoundOverviewEntity> getOverview() => _remote.getOverview();

  @override
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query) =>
      _remote.getSounds(query);

  @override
  Future<SoundEntity> createSound(CreateSoundData data) =>
      _remote.createSound(data);

  @override
  Future<SoundEntity> uploadSound(UploadSoundData data) =>
      _remote.uploadSound(data);

  @override
  Future<SoundEntity> updateSound(String soundId, UpdateSoundData data) =>
      _remote.updateSound(soundId, data);

  @override
  Future<SoundEntity> activateSound(String soundId) =>
      _remote.activateSound(soundId);

  @override
  Future<SoundEntity> deactivateSound(String soundId) =>
      _remote.deactivateSound(soundId);

  @override
  Future<void> deleteSound(String soundId) => _remote.deleteSound(soundId);

  @override
  Future<BulkSoundActionResultEntity> bulkAction(
    BulkSoundActionRequest request,
  ) =>
      _remote.bulkAction(request);
}
