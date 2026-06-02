import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<List<({String name, Uint8List bytes})>> pickMediaFiles() async {
  final input = html.FileUploadInputElement()
    ..multiple = true
    ..accept = 'image/*,video/*,.jpg,.jpeg,.png,.webp,.gif,.mp4,.mov,.webm';

  // Required on Flutter Web so the native file dialog works reliably.
  html.document.body?.append(input);

  final completer = Completer<List<({String name, Uint8List bytes})>>();

  void complete(List<({String name, Uint8List bytes})> value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    input.remove();
  }

  input.onChange.listen((_) async {
    try {
      final files = input.files;
      if (files == null || files.isEmpty) {
        complete([]);
        return;
      }

      final picked = <({String name, Uint8List bytes})>[];
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final bytes = await _readFileBytes(file);
        if (bytes.isNotEmpty) {
          picked.add((name: file.name, bytes: bytes));
        }
      }
      complete(picked);
    } catch (_) {
      complete([]);
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
