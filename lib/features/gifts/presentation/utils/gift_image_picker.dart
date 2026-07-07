// Conditional export: use the html implementation on Flutter Web,
// and the stub (returns null) on every other platform.
export 'gift_image_picker_stub.dart'
    if (dart.library.html) 'gift_image_picker_web.dart';
