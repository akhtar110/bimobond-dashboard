import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Applies a PNG Hald CLUT (or simple 2D LUT) to a source [ui.Image].
Future<ui.Image?> applyFePreviewLut(
  ui.Image source,
  ui.Image lut, {
  int maxWidth = 720,
}) async {
  final targetWidth = source.width > maxWidth ? maxWidth : source.width;
  final scale = targetWidth / source.width;
  final targetHeight = (source.height * scale).round();

  final sourceBytes = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
  final lutBytes = await lut.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (sourceBytes == null || lutBytes == null) return null;

  final args = _HaldLutArgs(
    sourceRgba: sourceBytes.buffer.asUint8List(
      sourceBytes.offsetInBytes,
      sourceBytes.lengthInBytes,
    ),
    sourceWidth: source.width,
    sourceHeight: source.height,
    lutRgba: lutBytes.buffer.asUint8List(
      lutBytes.offsetInBytes,
      lutBytes.lengthInBytes,
    ),
    lutWidth: lut.width,
    lutHeight: lut.height,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    scale: scale,
  );

  // Web has no real isolates for this; VM uses a background isolate.
  final out = kIsWeb
      ? await _applyHaldLutChunked(args)
      : await compute(_applyHaldLutIsolate, args);

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    out,
    targetWidth,
    targetHeight,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

class _HaldLutArgs {
  const _HaldLutArgs({
    required this.sourceRgba,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.lutRgba,
    required this.lutWidth,
    required this.lutHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.scale,
  });

  final Uint8List sourceRgba;
  final int sourceWidth;
  final int sourceHeight;
  final Uint8List lutRgba;
  final int lutWidth;
  final int lutHeight;
  final int targetWidth;
  final int targetHeight;
  final double scale;
}

Uint8List _applyHaldLutIsolate(_HaldLutArgs args) {
  return _applyHaldLutSync(args);
}

Future<Uint8List> _applyHaldLutChunked(_HaldLutArgs args) async {
  final sourceBytes = ByteData.sublistView(args.sourceRgba);
  final lutBytes = ByteData.sublistView(args.lutRgba);
  final out = Uint8List(args.targetWidth * args.targetHeight * 4);
  final haldLevel = _haldLevelForSize(args.lutWidth, args.lutHeight);

  for (var y = 0; y < args.targetHeight; y++) {
    for (var x = 0; x < args.targetWidth; x++) {
      final sx = ((x / args.scale).round()).clamp(0, args.sourceWidth - 1);
      final sy = ((y / args.scale).round()).clamp(0, args.sourceHeight - 1);
      final srcIndex = (sy * args.sourceWidth + sx) * 4;
      final r = sourceBytes.getUint8(srcIndex);
      final g = sourceBytes.getUint8(srcIndex + 1);
      final b = sourceBytes.getUint8(srcIndex + 2);

      final color = haldLevel != null
          ? _sampleHaldLut(
              r: r,
              g: g,
              b: b,
              lutBytes: lutBytes,
              lutWidth: args.lutWidth,
              level: haldLevel,
            )
          : _samplePlanarLut(
              r: r,
              g: g,
              b: b,
              lutBytes: lutBytes,
              lutWidth: args.lutWidth,
              lutHeight: args.lutHeight,
            );

      final outIndex = (y * args.targetWidth + x) * 4;
      out[outIndex] = color[0];
      out[outIndex + 1] = color[1];
      out[outIndex + 2] = color[2];
      out[outIndex + 3] = 255;
    }
    // Yield so the dialog can paint the loading state / stay responsive.
    if ((y & 31) == 31) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return out;
}

Uint8List _applyHaldLutSync(_HaldLutArgs args) {
  final sourceBytes = ByteData.sublistView(args.sourceRgba);
  final lutBytes = ByteData.sublistView(args.lutRgba);
  final out = Uint8List(args.targetWidth * args.targetHeight * 4);
  final haldLevel = _haldLevelForSize(args.lutWidth, args.lutHeight);

  for (var y = 0; y < args.targetHeight; y++) {
    for (var x = 0; x < args.targetWidth; x++) {
      final sx = ((x / args.scale).round()).clamp(0, args.sourceWidth - 1);
      final sy = ((y / args.scale).round()).clamp(0, args.sourceHeight - 1);
      final srcIndex = (sy * args.sourceWidth + sx) * 4;
      final r = sourceBytes.getUint8(srcIndex);
      final g = sourceBytes.getUint8(srcIndex + 1);
      final b = sourceBytes.getUint8(srcIndex + 2);

      final color = haldLevel != null
          ? _sampleHaldLut(
              r: r,
              g: g,
              b: b,
              lutBytes: lutBytes,
              lutWidth: args.lutWidth,
              level: haldLevel,
            )
          : _samplePlanarLut(
              r: r,
              g: g,
              b: b,
              lutBytes: lutBytes,
              lutWidth: args.lutWidth,
              lutHeight: args.lutHeight,
            );

      final outIndex = (y * args.targetWidth + x) * 4;
      out[outIndex] = color[0];
      out[outIndex + 1] = color[1];
      out[outIndex + 2] = color[2];
      out[outIndex + 3] = 255;
    }
  }
  return out;
}

/// Hald CLUT level N uses an N³ × N³ image (level 8 → 512×512).
int? _haldLevelForSize(int width, int height) {
  if (width != height || width < 8) return null;
  final root = math.pow(width, 1 / 3).round();
  if (root < 2 || root > 64) return null;
  if (root * root * root != width) return null;
  return root;
}

/// Correct Hald CLUT sampling with blue-slice interpolation.
List<int> _sampleHaldLut({
  required int r,
  required int g,
  required int b,
  required ByteData lutBytes,
  required int lutWidth,
  required int level,
}) {
  final blueMax = level * level - 1;
  final cellSize = level * level;
  final rf = (r.clamp(0, 255)) / 255.0;
  final gf = (g.clamp(0, 255)) / 255.0;
  final blue = ((b.clamp(0, 255)) / 255.0) * blueMax;
  final blue0 = blue.floor().clamp(0, blueMax);
  final blue1 = (blue0 + 1).clamp(0, blueMax);
  final t = blue - blue0;

  final c0 = _sampleHaldSlice(
    lutBytes: lutBytes,
    lutWidth: lutWidth,
    level: level,
    cellSize: cellSize,
    blueIndex: blue0,
    rf: rf,
    gf: gf,
  );
  if (blue0 == blue1 || t <= 0) return c0;

  final c1 = _sampleHaldSlice(
    lutBytes: lutBytes,
    lutWidth: lutWidth,
    level: level,
    cellSize: cellSize,
    blueIndex: blue1,
    rf: rf,
    gf: gf,
  );

  return [
    (c0[0] + (c1[0] - c0[0]) * t).round().clamp(0, 255),
    (c0[1] + (c1[1] - c0[1]) * t).round().clamp(0, 255),
    (c0[2] + (c1[2] - c0[2]) * t).round().clamp(0, 255),
  ];
}

List<int> _sampleHaldSlice({
  required ByteData lutBytes,
  required int lutWidth,
  required int level,
  required int cellSize,
  required int blueIndex,
  required double rf,
  required double gf,
}) {
  final qx = blueIndex % level;
  final qy = blueIndex ~/ level;
  final x = qx * cellSize + rf * (cellSize - 1);
  final y = qy * cellSize + gf * (cellSize - 1);
  return _bilinearSample(lutBytes, lutWidth, lutWidth, x, y);
}

/// Fallback for non-Hald image LUTs (maps R/G; ignores structured blue).
List<int> _samplePlanarLut({
  required int r,
  required int g,
  required int b,
  required ByteData lutBytes,
  required int lutWidth,
  required int lutHeight,
}) {
  final x = (r / 255.0) * (lutWidth - 1);
  final y = (g / 255.0) * (lutHeight - 1);
  return _bilinearSample(lutBytes, lutWidth, lutHeight, x, y);
}

List<int> _bilinearSample(
  ByteData lutBytes,
  int lutWidth,
  int lutHeight,
  double x,
  double y,
) {
  final x0 = x.floor().clamp(0, lutWidth - 1);
  final y0 = y.floor().clamp(0, lutHeight - 1);
  final x1 = (x0 + 1).clamp(0, lutWidth - 1);
  final y1 = (y0 + 1).clamp(0, lutHeight - 1);
  final tx = (x - x0).clamp(0.0, 1.0);
  final ty = (y - y0).clamp(0.0, 1.0);

  final c00 = _readRgb(lutBytes, lutWidth, x0, y0);
  final c10 = _readRgb(lutBytes, lutWidth, x1, y0);
  final c01 = _readRgb(lutBytes, lutWidth, x0, y1);
  final c11 = _readRgb(lutBytes, lutWidth, x1, y1);

  return [
    _lerpChannel(c00[0], c10[0], c01[0], c11[0], tx, ty),
    _lerpChannel(c00[1], c10[1], c01[1], c11[1], tx, ty),
    _lerpChannel(c00[2], c10[2], c01[2], c11[2], tx, ty),
  ];
}

List<int> _readRgb(ByteData lutBytes, int lutWidth, int x, int y) {
  final index = (y * lutWidth + x) * 4;
  if (index + 2 >= lutBytes.lengthInBytes) return const [0, 0, 0];
  return [
    lutBytes.getUint8(index),
    lutBytes.getUint8(index + 1),
    lutBytes.getUint8(index + 2),
  ];
}

int _lerpChannel(int c00, int c10, int c01, int c11, double tx, double ty) {
  final top = c00 + (c10 - c00) * tx;
  final bottom = c01 + (c11 - c01) * tx;
  return (top + (bottom - top) * ty).round().clamp(0, 255);
}
