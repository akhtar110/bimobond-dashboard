import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Visual simulation of a CamerAwesome engine filter on preview media.
class CameraEngineFilterLook {
  const CameraEngineFilterLook({
    this.colorMatrix,
    this.overlayColor,
    this.overlayOpacity = 0,
  });

  const CameraEngineFilterLook.none() : this();

  final List<double>? colorMatrix;
  final Color? overlayColor;
  final double overlayOpacity;

  static const identityMatrix = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  bool get hasEffect =>
      colorMatrix != null ||
      (overlayColor != null && overlayOpacity > 0);
}

CameraEngineFilterLook cameraEngineFilterLookForKey(String? engineKey) {
  final key = engineKey?.trim();
  if (key == null || key.isEmpty || key == 'Original') {
    return const CameraEngineFilterLook.none();
  }
  return _engineLooks[key] ?? _genericTintedLook(key);
}

CameraEngineFilterLook _genericTintedLook(String key) {
  final hash = key.codeUnits.fold<int>(0, (a, b) => a + b);
  final hue = (hash % 360).toDouble();
  return CameraEngineFilterLook(
    overlayColor: HSVColor.fromAHSV(1, hue, 0.35, 1).toColor(),
    overlayOpacity: 0.18,
  );
}

List<double> cameraEngineFilterMatrix({
  double rR = 1,
  double rG = 0,
  double rB = 0,
  double rBias = 0,
  double gR = 0,
  double gG = 1,
  double gB = 0,
  double gBias = 0,
  double bR = 0,
  double bG = 0,
  double bB = 1,
  double bBias = 0,
  double sat = 1,
}) {
  if (sat == 1) {
    return [
      rR, rG, rB, 0, rBias,
      gR, gG, gB, 0, gBias,
      bR, bG, bB, 0, bBias,
      0, 0, 0, 1, 0,
    ];
  }
  const lumR = 0.2126;
  const lumG = 0.7152;
  const lumB = 0.0722;
  final inv = 1 - sat;
  return [
    lumR * inv + sat * rR, lumG * inv + sat * rG, lumB * inv + sat * rB, 0,
    rBias,
    lumR * inv + sat * gR, lumG * inv + sat * gG, lumB * inv + sat * gB, 0,
    gBias,
    lumR * inv + sat * bR, lumG * inv + sat * bG, lumB * inv + sat * bB, 0,
    bBias,
    0, 0, 0, 1, 0,
  ];
}

const _grayscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

final Map<String, CameraEngineFilterLook> _engineLooks = {
  'Amaro': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.08,
      gG: 1.02,
      bB: 0.92,
      rBias: 12,
      gBias: 8,
    ),
    overlayColor: const Color(0xFFFFE0B2),
    overlayOpacity: 0.12,
  ),
  'Juno': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.12,
      gG: 1.04,
      bB: 0.88,
      rBias: 16,
    ),
    overlayColor: const Color(0xFFFFCC80),
    overlayOpacity: 0.14,
  ),
  'Lark': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.04,
      gG: 1.06,
      bB: 1.1,
      bBias: 10,
    ),
    overlayColor: const Color(0xFFB3E5FC),
    overlayOpacity: 0.1,
  ),
  'Addictive Red': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.25,
      gG: 0.88,
      bB: 0.82,
      rBias: 20,
    ),
    overlayColor: const Color(0xFFE53935),
    overlayOpacity: 0.22,
  ),
  'Addictive Blue': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 0.82,
      gG: 0.9,
      bB: 1.25,
      bBias: 18,
    ),
    overlayColor: const Color(0xFF1E88E5),
    overlayOpacity: 0.22,
  ),
  'Clarendon': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.18,
      gG: 1.12,
      bB: 1.08,
      sat: 1.15,
    ),
  ),
  'Reyes': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.06,
      gG: 1.02,
      bB: 0.94,
      sat: 0.82,
      rBias: 18,
    ),
    overlayColor: const Color(0xFFFFF3E0),
    overlayOpacity: 0.16,
  ),
  'Aden': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      sat: 0.75,
      rBias: 14,
      gBias: 10,
      bBias: 6,
    ),
    overlayColor: const Color(0xFFFFE0B2),
    overlayOpacity: 0.1,
  ),
  'Perpetua': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.05,
      gG: 1.08,
      bB: 1.02,
      sat: 0.95,
    ),
    overlayColor: const Color(0xFFC8E6C9),
    overlayOpacity: 0.1,
  ),
  'Walden': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 0.95,
      gG: 1.05,
      bB: 1.15,
      bBias: 8,
    ),
    overlayColor: const Color(0xFF80DEEA),
    overlayOpacity: 0.18,
  ),
  'Ginza': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.1,
      gG: 1.02,
      bB: 0.95,
      sat: 1.1,
    ),
    overlayColor: const Color(0xFFFFAB91),
    overlayOpacity: 0.12,
  ),
  'Sierra': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(sat: 0.88, rBias: 12, gBias: 8),
    overlayColor: const Color(0xFFD7CCC8),
    overlayOpacity: 0.14,
  ),
  'Hefe': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.15,
      gG: 1.05,
      bB: 0.9,
      sat: 1.2,
    ),
    overlayColor: const Color(0xFFFF8A65),
    overlayOpacity: 0.1,
  ),
  'Inkwell': const CameraEngineFilterLook(colorMatrix: _grayscale),
  'Moon': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 0.9,
      gG: 0.9,
      bB: 0.95,
      rBias: 20,
      gBias: 20,
      bBias: 24,
      sat: 0.15,
    ),
  ),
  'Willow': const CameraEngineFilterLook(colorMatrix: _grayscale),
  'Brannan': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(sat: 0.7, rBias: 16, gBias: 10),
    overlayColor: const Color(0xFFBCAAA4),
    overlayOpacity: 0.2,
  ),
  'Stinson': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      sat: 0.65,
      rBias: 22,
      gBias: 18,
      bBias: 12,
    ),
    overlayColor: const Color(0xFFFFF8E1),
    overlayOpacity: 0.2,
  ),
  'Sutro': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 0.9,
      gG: 0.88,
      bB: 0.85,
      sat: 0.8,
      rBias: 8,
    ),
    overlayColor: const Color(0xFF5D4037),
    overlayOpacity: 0.15,
  ),
  'Hudson': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 0.92,
      gG: 0.96,
      bB: 1.12,
      bBias: 10,
    ),
    overlayColor: const Color(0xFF90CAF9),
    overlayOpacity: 0.2,
  ),
  'LoFi': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.1,
      gG: 1.05,
      bB: 0.95,
      sat: 1.25,
    ),
    overlayColor: const Color(0xFF3E2723),
    overlayOpacity: 0.12,
  ),
  'Slumber': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      sat: 0.55,
      rBias: 18,
      gBias: 14,
      bBias: 20,
    ),
    overlayColor: const Color(0xFF7986CB),
    overlayOpacity: 0.16,
  ),
  'Dogpatch': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(sat: 0.85, rR: 1.05, bB: 0.9),
    overlayColor: const Color(0xFF8D6E63),
    overlayOpacity: 0.14,
  ),
  'Brooklyn': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(sat: 0.9, rBias: 10),
    overlayColor: const Color(0xFFB0BEC5),
    overlayOpacity: 0.12,
  ),
  'Gingham': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.02,
      gG: 1.06,
      bB: 1.08,
      sat: 0.9,
      bBias: 8,
    ),
    overlayColor: const Color(0xFFE1F5FE),
    overlayOpacity: 0.12,
  ),
  'XProII': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.2,
      gG: 1.1,
      bB: 0.95,
      sat: 1.3,
    ),
    overlayColor: const Color(0xFF4E342E),
    overlayOpacity: 0.1,
  ),
  'Ludwig': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(sat: 0.92, rBias: 8, gBias: 6),
    overlayColor: const Color(0xFFFFECB3),
    overlayOpacity: 0.1,
  ),
  'Crema': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      sat: 0.78,
      rBias: 20,
      gBias: 16,
      bBias: 10,
    ),
    overlayColor: const Color(0xFFFFF3E0),
    overlayOpacity: 0.18,
  ),
  'Ashby': CameraEngineFilterLook(
    colorMatrix: cameraEngineFilterMatrix(
      rR: 1.08,
      gG: 1.02,
      bB: 0.92,
      sat: 1.05,
    ),
    overlayColor: const Color(0xFFFFCCBC),
    overlayOpacity: 0.14,
  ),
};

/// Applies the engine filter look to [child] (typically the preview photo).
Widget applyCameraEngineFilterLook({
  required Widget child,
  required String? engineKey,
}) {
  final look = cameraEngineFilterLookForKey(engineKey);
  if (!look.hasEffect) return child;

  Widget result = child;
  if (look.colorMatrix != null) {
    result = ColorFiltered(
      colorFilter: ColorFilter.matrix(look.colorMatrix!),
      child: result,
    );
  }
  if (look.overlayColor != null && look.overlayOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: look.overlayColor!.withValues(alpha: look.overlayOpacity),
        ),
      ],
    );
  }
  return result;
}

Future<Uint8List> applyCameraEngineFilterLookToImageBytes(
  Uint8List bytes,
  String? engineKey,
) async {
  final look = cameraEngineFilterLookForKey(engineKey);
  if (!look.hasEffect) return bytes;

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    if (look.colorMatrix != null) {
      paint.colorFilter = ColorFilter.matrix(look.colorMatrix!);
    }
    canvas.drawImage(image, Offset.zero, paint);
    if (look.overlayColor != null && look.overlayOpacity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Paint()
          ..color = look.overlayColor!.withValues(alpha: look.overlayOpacity),
      );
    }
    final picture = recorder.endRecording();
    final filtered = await picture.toImage(image.width, image.height);
    final byteData =
        await filtered.toByteData(format: ui.ImageByteFormat.png);
    filtered.dispose();
    if (byteData == null) return bytes;
    return byteData.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
