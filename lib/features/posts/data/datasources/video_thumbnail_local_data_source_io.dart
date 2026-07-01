import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'video_thumbnail_local_data_source.dart';

class VideoThumbnailLocalDataSourceImpl
    implements VideoThumbnailLocalDataSource {
  @override
  Future<Uint8List?> generateFromVideoBytes({
    required Uint8List videoBytes,
    required String fileName,
  }) async {
    if (videoBytes.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final videoPath = '${tempDir.path}/thumb_src_$safeName';
    final videoFile = File(videoPath);

    try {
      await videoFile.writeAsBytes(videoBytes, flush: true);

      return VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 85,
        timeMs: 1000,
      );
    } catch (_) {
      return null;
    } finally {
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    }
  }
}
