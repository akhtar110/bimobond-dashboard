import 'dart:typed_data';

Future<({String name, Uint8List bytes})?> pickArOverlayJsonFile() async {
  return pickArOverlayAnimationFile();
}

Future<({String name, Uint8List bytes})?> pickArOverlayAnimationFile() async {
  throw UnsupportedError(
    'AR overlay animation picking is only supported on web.',
  );
}

Future<({String name, Uint8List bytes})?> pickArOverlayImageFile() async {
  throw UnsupportedError(
    'AR overlay image picking is only supported on web.',
  );
}
