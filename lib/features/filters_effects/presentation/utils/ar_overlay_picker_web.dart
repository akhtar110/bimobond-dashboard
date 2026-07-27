import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({String name, Uint8List bytes})?> pickArOverlayJsonFile() async {
  return pickArOverlayAnimationFile();
}

/// Picks a Lottie JSON or MP4 video file for an AR overlay animation asset.
Future<({String name, Uint8List bytes})?> pickArOverlayAnimationFile() async {
  return _pickFile(
    accept:
        '.json,.lottie,.mp4,application/json,text/json,video/mp4,video/*',
    preferTextFallback: true,
  );
}

Future<({String name, Uint8List bytes})?> pickArOverlayImageFile() async {
  return _pickFile(accept: 'image/*,.png,.jpg,.jpeg,.webp,.gif');
}

Future<({String name, Uint8List bytes})?> _pickFile({
  required String accept,
  bool preferTextFallback = false,
}) async {
  final input = html.FileUploadInputElement()
    ..multiple = false
    ..accept = accept;

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
      var bytes = await _readBytes(file);
      final lowerName = file.name.toLowerCase();
      final likelyText = preferTextFallback &&
          (lowerName.endsWith('.json') ||
              lowerName.endsWith('.lottie') ||
              lowerName.contains('.json'));
      if (bytes.isEmpty && likelyText) {
        bytes = await _readTextAsBytes(file);
      }
      if (bytes.isEmpty) {
        complete(null);
        return;
      }
      complete((name: file.name, bytes: bytes));
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
      completer.complete(Uint8List.view(result));
    } else if (result is Uint8List) {
      completer.complete(result);
    } else if (result is TypedData) {
      completer.complete(
        Uint8List.view(
          result.buffer,
          result.offsetInBytes,
          result.lengthInBytes,
        ),
      );
    } else {
      completer.complete(Uint8List(0));
    }
  });
  reader.onError.listen((_) => completer.complete(Uint8List(0)));
  reader.readAsArrayBuffer(file);
  return completer.future;
}

Future<Uint8List> _readTextAsBytes(html.File file) async {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();
  reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is String && result.isNotEmpty) {
      completer.complete(Uint8List.fromList(utf8.encode(result)));
    } else {
      completer.complete(Uint8List(0));
    }
  });
  reader.onError.listen((_) => completer.complete(Uint8List(0)));
  reader.readAsText(file);
  return completer.future;
}
