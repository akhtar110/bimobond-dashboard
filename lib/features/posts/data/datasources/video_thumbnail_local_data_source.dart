import 'dart:typed_data';

/// Generates a JPEG still frame from local video bytes.
abstract class VideoThumbnailLocalDataSource {
  Future<Uint8List?> generateFromVideoBytes({
    required Uint8List videoBytes,
    required String fileName,
  });
}
