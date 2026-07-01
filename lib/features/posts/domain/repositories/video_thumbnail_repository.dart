import 'dart:typed_data';

abstract class VideoThumbnailRepository {
  Future<Uint8List?> generateThumbnail({
    required Uint8List videoBytes,
    required String fileName,
  });

  Future<String?> uploadThumbnail(Uint8List thumbnailBytes);
}
