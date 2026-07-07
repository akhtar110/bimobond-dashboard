import '../../../sound_management/domain/entities/sound_entities.dart';
import '../entities/create_post_location_entity.dart';
import '../repositories/create_post_repository.dart';

class SearchCreatePostSounds {
  const SearchCreatePostSounds(this._repository);

  final CreatePostRepository _repository;

  Future<List<SoundEntity>> call({
    required int page,
    required int limit,
    String? search,
  }) {
    return _repository.searchSounds(page: page, limit: limit, search: search);
  }
}

class UploadCreatePostSound {
  const UploadCreatePostSound(this._repository);

  final CreatePostRepository _repository;

  Future<SoundEntity> call({
    required List<int> bytes,
    required String filename,
    required String name,
    required int duration,
  }) {
    return _repository.uploadSound(
      bytes: bytes,
      filename: filename,
      name: name,
      duration: duration,
    );
  }
}

class SearchCreatePostLocations {
  const SearchCreatePostLocations(this._repository);

  final CreatePostRepository _repository;

  Future<List<CreatePostLocationEntity>> call({
    required String query,
    required int page,
    required int limit,
  }) {
    return _repository.searchLocations(
      query: query,
      page: page,
      limit: limit,
    );
  }
}

class GetTrendingCreatePostSounds {
  const GetTrendingCreatePostSounds(this._repository);

  final CreatePostRepository _repository;

  Future<List<SoundEntity>> call() => _repository.getTrendingSounds();
}
