import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({String name, Uint8List bytes})?> pickAudioFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'audio/*,.mp3,.wav,.aac,.m4a,.ogg,.webm';

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
      final file = files.first;
      final bytes = await _readFileBytes(file);
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

Future<({String name, Uint8List bytes})?> pickCoverImageFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*,.jpg,.jpeg,.png,.webp';

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
      final file = files.first;
      final bytes = await _readFileBytes(file);
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

Future<Uint8List> _readFileBytes(html.File file) async {
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

const kMaxAudioUploadBytes = 20 * 1024 * 1024;

bool isAllowedAudioFilename(String filename) {
  final lower = filename.toLowerCase();
  return lower.endsWith('.mp3') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.m4a') ||
      lower.endsWith('.ogg') ||
      lower.endsWith('.webm');
}
