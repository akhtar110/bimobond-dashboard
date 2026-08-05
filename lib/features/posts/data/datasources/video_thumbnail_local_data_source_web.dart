import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../../../create_post/presentation/utils/create_post_video_source.dart';
import 'video_thumbnail_local_data_source.dart';

class VideoThumbnailLocalDataSourceImpl
    implements VideoThumbnailLocalDataSource {
  @override
  Future<Uint8List?> generateFromVideoBytes({
    required Uint8List videoBytes,
    required String fileName,
  }) async {
    if (videoBytes.isEmpty) return null;

    final objectUrl = createVideoPreviewUri(videoBytes, fileName);
    if (objectUrl == null) return null;

    final video = html.VideoElement()
      ..src = objectUrl
      ..muted = true
      ..preload = 'auto'
      ..crossOrigin = 'anonymous';

    try {
      await video.onLoadedMetadata.first.timeout(const Duration(seconds: 30));

      final rawDur = video.duration * 1000;
      final durationMs = (rawDur.isNaN || rawDur.isInfinite || rawDur < 0) ? 0.0 : rawDur;
      final seekMs = durationMs > 500 ? 500 : 0;
      video.currentTime = seekMs / 1000;

      await video.onSeeked.first.timeout(const Duration(seconds: 15));

      final width = video.videoWidth;
      final height = video.videoHeight;
      if (width <= 0 || height <= 0) return null;

      final canvas = html.CanvasElement(width: width, height: height);
      canvas.context2D.drawImage(video, 0, 0);

      final blob = await canvas.toBlob('image/jpeg', 0.85);
      return _readBlobBytes(blob);
    } catch (_) {
      return null;
    } finally {
      disposeVideoPreviewUri(objectUrl);
      video.remove();
    }
  }
}

Future<Uint8List> _readBlobBytes(html.Blob blob) {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(result.asUint8List());
    } else if (result is Uint8List) {
      completer.complete(result);
    } else {
      completer.complete(Uint8List(0));
    }
  });

  reader.onError.listen((_) => completer.complete(Uint8List(0)));
  reader.readAsArrayBuffer(blob);
  return completer.future;
}
