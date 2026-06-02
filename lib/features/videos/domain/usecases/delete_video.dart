import '../repositories/videos_repository.dart';

class DeleteVideo {
  const DeleteVideo(this.repository);
  final VideosRepository repository;

  Future<void> call(String videoId) => repository.deleteVideo(videoId);
}
