import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/videos_repository.dart';
import '../datasources/videos_remote_data_source.dart';

class VideosRepositoryImpl implements VideosRepository {
  const VideosRepositoryImpl(this.remoteDataSource);
  final VideosRemoteDataSource remoteDataSource;

  @override
  Future<void> deleteVideo(String videoId) => remoteDataSource.deleteVideo(videoId);

  @override
  Future<List<VideoEntity>> getVideos({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  }) => remoteDataSource.getVideos(
        page: page,
        limit: limit,
        filter: filter,
        userId: userId,
      );
}
