import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({String name, Uint8List bytes})?> pickFilterLutFile() async {
  final input = html.FileUploadInputElement()
    ..multiple = false
    ..accept = '.cube,image/png,.png';

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
      if (!isAllowedFilterLutFilename(file.name)) {
        complete(null);
        return;
      }
      final bytes = await _readBytes(file);
      complete(bytes.isEmpty ? null : (name: file.name, bytes: bytes));
    } catch (_) {
      complete(null);
    }
  });

  input.click();
  return completer.future;
}

bool isAllowedFilterLutFilename(String filename) {
  final lower = filename.toLowerCase();
  return lower.endsWith('.cube') || lower.endsWith('.png');
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
