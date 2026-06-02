import '../entities/video_entity.dart';

abstract class VideosRepository {
  Future<List<VideoEntity>> getVideos({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  });

  Future<void> deleteVideo(String videoId);
}
