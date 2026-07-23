import 'dart:typed_data';

import '../entities/sound_entities.dart';
import '../entities/sound_group_entities.dart';

abstract class SoundManagementRepository {
  Future<SoundOverviewEntity> getOverview();
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query);
  Future<SoundEntity> getSoundById(String soundId);
  Future<SoundEntity> createSound(CreateSoundData data);
  Future<SoundEntity> uploadSound(UploadSoundData data);
  Future<String> uploadSoundFile(Uint8List bytes, String filename);
  Future<SoundEntity> updateSound(String soundId, UpdateSoundData data);
  Future<SoundEntity> activateSound(String soundId);
  Future<SoundEntity> deactivateSound(String soundId);
  Future<void> deleteSound(String soundId);
  Future<BulkSoundActionResultEntity> bulkAction(BulkSoundActionRequest request);

  Future<List<SoundGroupEntity>> getSoundGroups();
  Future<SoundGroupEntity> createSoundGroup(CreateSoundGroupData data);
  Future<List<SoundGroupEntity>> reorderSoundGroups(
    List<SoundGroupReorderItem> items,
  );
  Future<SoundGroupEntity> updateSoundGroup(
    String groupId,
    UpdateSoundGroupData data,
  );
  Future<void> deleteSoundGroup(String groupId);
  Future<SoundGroupEntity> replaceGroupSounds(
    String groupId,
    List<SoundGroupMembershipItem> sounds,
  );
}
