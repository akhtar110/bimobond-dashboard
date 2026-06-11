import 'dart:typed_data';

/// Non-web platforms: icon upload via file picker is not supported yet.
Future<({String name, Uint8List bytes})?> pickCategoryIcon() async => null;
