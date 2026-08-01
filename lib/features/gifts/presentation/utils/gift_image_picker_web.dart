import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Opens the native file dialog (images only) and returns the first selected
/// file as in-memory bytes + its original filename.
/// Returns [null] if the user cancels.
// ignore: avoid_web_libraries_in_flutter
Future<({String name, Uint8List bytes})?> pickGiftImage() async {
  return _pickFile(accept: 'image/*,.jpg,.jpeg,.png,.webp,.gif,.svg,image/svg+xml');
}

/// Opens the native file dialog for gift animation assets
/// (MP4 / PAG / JSON / Lottie / GIF / SWF).
/// Returns [null] if the user cancels.
// ignore: avoid_web_libraries_in_flutter
Future<({String name, Uint8List bytes})?> pickGiftAnimation() async {
  return _pickFile(
    accept:
        'video/mp4,video/webm,video/*,.mp4,.webm,.mov,.pag,.json,.lottie,.gif,.swf,image/gif,application/x-shockwave-flash,application/json,application/zip,application/octet-stream',
  );
}

/// Opens the native file dialog for gift audio assets (MP3 / WAV / OGG / M4A).
/// Returns [null] if the user cancels.
// ignore: avoid_web_libraries_in_flutter
Future<({String name, Uint8List bytes})?> pickGiftAudio() async {
  return _pickFile(
    accept: 'audio/*,.mp3,.wav,.ogg,.m4a,.aac',
  );
}

Future<({String name, Uint8List bytes})?> _pickFile({
  required String accept,
}) async {
  final input = html.FileUploadInputElement()
    ..multiple = false
    ..accept = accept;

  // Appending to the DOM is required for reliable dialog triggering on Chrome.
  html.document.body?.append(input);

  final completer = Completer<({String name, Uint8List bytes})?>();

  void complete(({String name, Uint8List bytes})? value) {
    if (!completer.isCompleted) completer.complete(value);
    input.remove();
  }

  input.onChange.listen((_) async {
    try {
      final files = input.files;
      if (files == null || files.isEmpty) {
        complete(null);
        return;
      }
      final file = files[0];
      final bytes = await _readBytes(file);
      complete(bytes.isEmpty ? null : (name: file.name, bytes: bytes));
    } catch (_) {
      complete(null);
    }
  });

  input.click();
  return completer.future;
}

Future<Uint8List> _readBytes(html.File file) async {
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
  reader.readAsArrayBuffer(file);
  return completer.future;
}
