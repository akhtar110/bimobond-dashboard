import '../../../sound_management/domain/entities/sound_entities.dart';
import '../entities/create_post_entity.dart';
import '../entities/create_post_location_entity.dart';

abstract class CreatePostRepository {
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files);

  Future<Map<String, dynamic>> createPost(CreatePostEntity entity);

  Future<List<SoundEntity>> searchSounds({
    required int page,
    required int limit,
    String? search,
  });

  Future<List<SoundEntity>> getTrendingSounds();

  Future<SoundEntity> uploadSound({
    required List<int> bytes,
    required String filename,
    required String name,
    required int duration,
  });

  Future<List<CreatePostLocationEntity>> searchLocations({
    required String query,
    required int page,
    required int limit,
  });
}
