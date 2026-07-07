import '../../../sound_management/domain/entities/sound_entities.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_location_entity.dart';
import '../../domain/repositories/create_post_repository.dart';
import '../datasources/create_post_auxiliary_remote_data_source.dart';
import '../datasources/create_post_remote_data_source.dart';
import '../models/create_post_dto.dart';

class CreatePostRepositoryImpl implements CreatePostRepository {
  CreatePostRepositoryImpl(this._dataSource, this._auxiliaryDataSource);

  final CreatePostRemoteDataSource _dataSource;
  final CreatePostAuxiliaryRemoteDataSource _auxiliaryDataSource;

  @override
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files) {
    return _dataSource.uploadMediaFiles(files);
  }

  @override
  Future<Map<String, dynamic>> createPost(CreatePostEntity entity) async {
    final dto = CreatePostDto.fromEntity(entity);
    return _dataSource.createPost(dto);
  }

  @override
  Future<List<SoundEntity>> searchSounds({
    required int page,
    required int limit,
    String? search,
  }) {
    return _auxiliaryDataSource.searchSounds(
      page: page,
      limit: limit,
      search: search,
    );
  }

  @override
  Future<List<SoundEntity>> getTrendingSounds() {
    return _auxiliaryDataSource.getTrendingSounds();
  }

  @override
  Future<SoundEntity> uploadSound({
    required List<int> bytes,
    required String filename,
    required String name,
    required int duration,
  }) {
    return _auxiliaryDataSource.uploadSound(
      bytes: bytes,
      filename: filename,
      name: name,
      duration: duration,
    );
  }

  @override
  Future<List<CreatePostLocationEntity>> searchLocations({
    required String query,
    required int page,
    required int limit,
  }) {
    return _auxiliaryDataSource.searchLocations(
      query: query,
      page: page,
      limit: limit,
    );
  }
}
