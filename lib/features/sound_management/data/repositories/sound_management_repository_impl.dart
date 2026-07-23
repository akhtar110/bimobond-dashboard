import 'dart:typed_data';

import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
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
  Future<SoundEntity> getSoundById(String soundId) =>
      _remote.getSoundById(soundId);

  @override
  Future<SoundEntity> createSound(CreateSoundData data) =>
      _remote.createSound(data);

  @override
  Future<SoundEntity> uploadSound(UploadSoundData data) =>
      _remote.uploadSound(data);

  @override
  Future<String> uploadSoundFile(Uint8List bytes, String filename) =>
      _remote.uploadSoundFile(bytes, filename);

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

  @override
  Future<List<SoundGroupEntity>> getSoundGroups() => _remote.getSoundGroups();

  @override
  Future<SoundGroupEntity> createSoundGroup(CreateSoundGroupData data) =>
      _remote.createSoundGroup(data);

  @override
  Future<List<SoundGroupEntity>> reorderSoundGroups(
    List<SoundGroupReorderItem> items,
  ) =>
      _remote.reorderSoundGroups(items);

  @override
  Future<SoundGroupEntity> updateSoundGroup(
    String groupId,
    UpdateSoundGroupData data,
  ) =>
      _remote.updateSoundGroup(groupId, data);

  @override
  Future<void> deleteSoundGroup(String groupId) =>
      _remote.deleteSoundGroup(groupId);

  @override
  Future<SoundGroupEntity> replaceGroupSounds(
    String groupId,
    List<SoundGroupMembershipItem> sounds,
  ) =>
      _remote.replaceGroupSounds(groupId, sounds);
}
