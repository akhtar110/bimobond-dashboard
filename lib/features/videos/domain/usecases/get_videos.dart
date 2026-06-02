import '../entities/video_entity.dart';
import '../repositories/videos_repository.dart';

class GetVideos {
  const GetVideos(this.repository);
  final VideosRepository repository;

  Future<List<VideoEntity>> call({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  }) => repository.getVideos(
        page: page,
        limit: limit,
        filter: filter,
        userId: userId,
      );
}
