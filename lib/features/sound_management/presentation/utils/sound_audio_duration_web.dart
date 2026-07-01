import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import '../../../../core/utils/media_url_resolver.dart';
import 'sound_audio_duration_parser.dart';

Future<int?> _probeWithHtmlAudio(String url) async {
  final audio = html.AudioElement()..preload = 'metadata';
  final completer = Completer<int?>();

  void complete(int? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  int? readDuration() {
    final seconds = audio.duration;
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) return null;
    return seconds.ceil();
  }

  audio.onLoadedMetadata.listen((_) => complete(readDuration()));
  audio.onDurationChange.listen((_) => complete(readDuration()));
  audio.onCanPlay.listen((_) => complete(readDuration()));
  audio.onError.listen((_) => complete(null));

  audio.src = url;
  audio.load();

  for (var attempt = 0; attempt < 120; attempt++) {
    if (completer.isCompleted) return completer.future;
    if (audio.readyState >= html.MediaElement.HAVE_METADATA) {
      final parsed = readDuration();
      if (parsed != null) {
        complete(parsed);
        return completer.future;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  unawaited(
    Future<void>.delayed(const Duration(seconds: 10), () => complete(null)),
  );
  return completer.future;
}

Future<int?> probeAudioDurationSeconds(String url) async {
  final fromAudio = await _probeWithHtmlAudio(url);
  if (fromAudio != null && fromAudio > 0) return fromAudio;

  final controller = VideoPlayerController.networkUrl(Uri.parse(url));
  try {
    await controller.initialize().timeout(const Duration(seconds: 15));
    final seconds = controller.value.duration.inSeconds;
    return seconds > 0 ? seconds : null;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}

Future<int?> probeAudioDurationFromBytes(List<int> bytes, String filename) async {
  final parsed = parseAudioDurationFromBytes(bytes, filename);
  if (parsed != null && parsed > 0) return parsed;

  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  try {
    return await probeAudioDurationSeconds(objectUrl);
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    html.Url.revokeObjectUrl(objectUrl);
  }
}

Future<int?> probeAudioDurationFromPath(String pathOrUrl) async {
  final resolved = resolveMediaUrl(pathOrUrl.trim());
  if (resolved == null || resolved.isEmpty) return null;
  return probeAudioDurationSeconds(resolved);
}
