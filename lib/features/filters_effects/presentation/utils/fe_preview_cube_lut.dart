import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

class FeCubeLut3D {
  const FeCubeLut3D({
    required this.size,
    required this.rgb,
    this.domainMin = const [0.0, 0.0, 0.0],
    this.domainMax = const [1.0, 1.0, 1.0],
  });

  final int size;
  final Float32List rgb;
  final List<double> domainMin;
  final List<double> domainMax;
}

FeCubeLut3D? parseFeCubeLut(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  var size = 0;
  final values = <double>[];
  var domainMin = <double>[0.0, 0.0, 0.0];
  var domainMax = <double>[1.0, 1.0, 1.0];

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final upper = line.toUpperCase();
    if (upper.startsWith('TITLE')) continue;

    if (upper.startsWith('DOMAIN_MIN')) {
      final parts = line.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 4) {
        domainMin = [
          double.tryParse(parts[1]) ?? 0.0,
          double.tryParse(parts[2]) ?? 0.0,
          double.tryParse(parts[3]) ?? 0.0,
        ];
      }
      continue;
    }
    if (upper.startsWith('DOMAIN_MAX')) {
      final parts = line.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 4) {
        domainMax = [
          double.tryParse(parts[1]) ?? 1.0,
          double.tryParse(parts[2]) ?? 1.0,
          double.tryParse(parts[3]) ?? 1.0,
        ];
      }
      continue;
    }

    if (upper.startsWith('LUT_3D_SIZE')) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        size = int.tryParse(parts.last) ?? 0;
      }
      continue;
    }

    // Skip other keywords (LUT_1D_SIZE, etc.)
    if (RegExp(r'^[A-Za-z_]').hasMatch(line) && !RegExp(r'^-?\d').hasMatch(line)) {
      continue;
    }

    final parts = line.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 3) continue;

    final r = double.tryParse(parts[0]);
    final g = double.tryParse(parts[1]);
    final b = double.tryParse(parts[2]);
    if (r == null || g == null || b == null) continue;
    values.addAll([r, g, b]);
  }

  if (size <= 0) {
    final inferred = _inferCubeSize(values.length ~/ 3);
    if (inferred == null) return null;
    size = inferred;
  }

  final expected = size * size * size * 3;
  if (values.length < expected) return null;

  return FeCubeLut3D(
    size: size,
    rgb: Float32List.fromList(values.take(expected).toList()),
    domainMin: domainMin,
    domainMax: domainMax,
  );
}

FeCubeLut3D? parseFeCubeLutBytes(Uint8List bytes) {
  try {
    return parseFeCubeLut(utf8.decode(bytes, allowMalformed: true));
  } catch (_) {
    return parseFeCubeLut(String.fromCharCodes(bytes));
  }
}

int? _inferCubeSize(int count) {
  for (var size = 2; size <= 256; size++) {
    if (size * size * size == count) return size;
  }
  return null;
}

/// True when bytes look like a PNG/JPEG image LUT (not a `.cube` text file).
bool isFeImageLutBytes(Uint8List bytes) {
  if (bytes.length < 4) return false;
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
  return false;
}

bool isFeCubeLutSource({String? url, String? filename, Uint8List? bytes}) {
  if (bytes != null && isFeImageLutBytes(bytes)) return false;

  if (filename != null && filename.toLowerCase().endsWith('.cube')) return true;
  if (url != null && url.toLowerCase().contains('.cube')) {
    final lower = url.toLowerCase();
    if (lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg')) {
      return false;
    }
    return true;
  }
  if (bytes != null && bytes.isNotEmpty) {
    final head = utf8
        .decode(bytes.take(160).toList(), allowMalformed: true)
        .toUpperCase();
    if (head.contains('LUT_3D_SIZE')) return true;
  }
  return false;
}

/// Applies a 3D `.cube` LUT at (near) full source resolution so the preview
/// stays sharp when displayed in the editor.
Future<ui.Image?> applyFePreviewCubeLut(
  ui.Image source,
  FeCubeLut3D lut, {
  int maxWidth = 720,
}) async {
  final targetWidth = source.width > maxWidth ? maxWidth : source.width;
  final scale = targetWidth / source.width;
  final targetHeight = (source.height * scale).round().clamp(1, 4096);

  final sourceBytes = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (sourceBytes == null) return null;

  final args = _CubeLutArgs(
    sourceRgba: sourceBytes.buffer.asUint8List(
      sourceBytes.offsetInBytes,
      sourceBytes.lengthInBytes,
    ),
    sourceWidth: source.width,
    sourceHeight: source.height,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    scale: scale,
    lutSize: lut.size,
    lutRgb: lut.rgb,
    domainMin: List<double>.from(lut.domainMin),
    domainMax: List<double>.from(lut.domainMax),
  );

  final out = kIsWeb
      ? await _applyCubeLutChunked(args)
      : await compute(_applyCubeLutIsolate, args);

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

class _CubeLutArgs {
  const _CubeLutArgs({
    required this.sourceRgba,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.scale,
    required this.lutSize,
    required this.lutRgb,
    required this.domainMin,
    required this.domainMax,
  });

  final Uint8List sourceRgba;
  final int sourceWidth;
  final int sourceHeight;
  final int targetWidth;
  final int targetHeight;
  final double scale;
  final int lutSize;
  final Float32List lutRgb;
  final List<double> domainMin;
  final List<double> domainMax;
}

Uint8List _applyCubeLutIsolate(_CubeLutArgs args) => _applyCubeLutSync(args);

Future<Uint8List> _applyCubeLutChunked(_CubeLutArgs args) async {
  final sourceBytes = ByteData.sublistView(args.sourceRgba);
  final out = Uint8List(args.targetWidth * args.targetHeight * 4);
  final size = args.lutSize;
  final maxIndex = size - 1;
  final dMin = args.domainMin;
  final dMax = args.domainMax;
  final lut = FeCubeLut3D(
    size: size,
    rgb: args.lutRgb,
    domainMin: dMin,
    domainMax: dMax,
  );

  for (var y = 0; y < args.targetHeight; y++) {
    for (var x = 0; x < args.targetWidth; x++) {
      final srcXf = x / args.scale;
      final srcYf = y / args.scale;
      final sx = srcXf.round().clamp(0, args.sourceWidth - 1);
      final sy = srcYf.round().clamp(0, args.sourceHeight - 1);
      final srcIndex = (sy * args.sourceWidth + sx) * 4;

      var r = sourceBytes.getUint8(srcIndex) / 255.0;
      var g = sourceBytes.getUint8(srcIndex + 1) / 255.0;
      var b = sourceBytes.getUint8(srcIndex + 2) / 255.0;

      r = _mapDomain(r, dMin[0], dMax[0]);
      g = _mapDomain(g, dMin[1], dMax[1]);
      b = _mapDomain(b, dMin[2], dMax[2]);

      final rf = r * maxIndex;
      final gf = g * maxIndex;
      final bf = b * maxIndex;

      final r0 = rf.floor().clamp(0, maxIndex);
      final g0 = gf.floor().clamp(0, maxIndex);
      final b0 = bf.floor().clamp(0, maxIndex);
      final r1 = (r0 + 1).clamp(0, maxIndex);
      final g1 = (g0 + 1).clamp(0, maxIndex);
      final b1 = (b0 + 1).clamp(0, maxIndex);

      final dr = rf - r0;
      final dg = gf - g0;
      final db = bf - b0;

      final c000 = _cubeSample(lut, r0, g0, b0);
      final c100 = _cubeSample(lut, r1, g0, b0);
      final c010 = _cubeSample(lut, r0, g1, b0);
      final c110 = _cubeSample(lut, r1, g1, b0);
      final c001 = _cubeSample(lut, r0, g0, b1);
      final c101 = _cubeSample(lut, r1, g0, b1);
      final c011 = _cubeSample(lut, r0, g1, b1);
      final c111 = _cubeSample(lut, r1, g1, b1);

      final c00 = _lerp3(c000, c100, dr);
      final c01 = _lerp3(c001, c101, dr);
      final c10 = _lerp3(c010, c110, dr);
      final c11 = _lerp3(c011, c111, dr);
      final c0 = _lerp3(c00, c10, dg);
      final c1 = _lerp3(c01, c11, dg);
      final color = _lerp3(c0, c1, db);

      final outIndex = (y * args.targetWidth + x) * 4;
      out[outIndex] = (color[0] * 255.0).round().clamp(0, 255);
      out[outIndex + 1] = (color[1] * 255.0).round().clamp(0, 255);
      out[outIndex + 2] = (color[2] * 255.0).round().clamp(0, 255);
      out[outIndex + 3] = 255;
    }
    if ((y & 31) == 31) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return out;
}

Uint8List _applyCubeLutSync(_CubeLutArgs args) {
  final sourceBytes = ByteData.sublistView(args.sourceRgba);
  final out = Uint8List(args.targetWidth * args.targetHeight * 4);
  final size = args.lutSize;
  final maxIndex = size - 1;
  final dMin = args.domainMin;
  final dMax = args.domainMax;
  final lut = FeCubeLut3D(
    size: size,
    rgb: args.lutRgb,
    domainMin: dMin,
    domainMax: dMax,
  );

  for (var y = 0; y < args.targetHeight; y++) {
    for (var x = 0; x < args.targetWidth; x++) {
      final srcXf = x / args.scale;
      final srcYf = y / args.scale;
      final sx = srcXf.round().clamp(0, args.sourceWidth - 1);
      final sy = srcYf.round().clamp(0, args.sourceHeight - 1);
      final srcIndex = (sy * args.sourceWidth + sx) * 4;

      var r = sourceBytes.getUint8(srcIndex) / 255.0;
      var g = sourceBytes.getUint8(srcIndex + 1) / 255.0;
      var b = sourceBytes.getUint8(srcIndex + 2) / 255.0;

      r = _mapDomain(r, dMin[0], dMax[0]);
      g = _mapDomain(g, dMin[1], dMax[1]);
      b = _mapDomain(b, dMin[2], dMax[2]);

      final rf = r * maxIndex;
      final gf = g * maxIndex;
      final bf = b * maxIndex;

      final r0 = rf.floor().clamp(0, maxIndex);
      final g0 = gf.floor().clamp(0, maxIndex);
      final b0 = bf.floor().clamp(0, maxIndex);
      final r1 = (r0 + 1).clamp(0, maxIndex);
      final g1 = (g0 + 1).clamp(0, maxIndex);
      final b1 = (b0 + 1).clamp(0, maxIndex);

      final dr = rf - r0;
      final dg = gf - g0;
      final db = bf - b0;

      final c000 = _cubeSample(lut, r0, g0, b0);
      final c100 = _cubeSample(lut, r1, g0, b0);
      final c010 = _cubeSample(lut, r0, g1, b0);
      final c110 = _cubeSample(lut, r1, g1, b0);
      final c001 = _cubeSample(lut, r0, g0, b1);
      final c101 = _cubeSample(lut, r1, g0, b1);
      final c011 = _cubeSample(lut, r0, g1, b1);
      final c111 = _cubeSample(lut, r1, g1, b1);

      final c00 = _lerp3(c000, c100, dr);
      final c01 = _lerp3(c001, c101, dr);
      final c10 = _lerp3(c010, c110, dr);
      final c11 = _lerp3(c011, c111, dr);
      final c0 = _lerp3(c00, c10, dg);
      final c1 = _lerp3(c01, c11, dg);
      final color = _lerp3(c0, c1, db);

      final outIndex = (y * args.targetWidth + x) * 4;
      out[outIndex] = (color[0] * 255.0).round().clamp(0, 255);
      out[outIndex + 1] = (color[1] * 255.0).round().clamp(0, 255);
      out[outIndex + 2] = (color[2] * 255.0).round().clamp(0, 255);
      out[outIndex + 3] = 255;
    }
  }
  return out;
}

double _mapDomain(double value, double min, double max) {
  if ((max - min).abs() < 1e-8) return value.clamp(0.0, 1.0);
  return ((value - min) / (max - min)).clamp(0.0, 1.0);
}

List<double> _cubeSample(FeCubeLut3D lut, int r, int g, int b) {
  // IRIDAS/Adobe order: blue varies slowest, then green, then red.
  final index = (b * lut.size * lut.size + g * lut.size + r) * 3;
  return [
    lut.rgb[index],
    lut.rgb[index + 1],
    lut.rgb[index + 2],
  ];
}

List<double> _lerp3(List<double> a, List<double> b, double t) {
  return [
    a[0] + (b[0] - a[0]) * t,
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
  ];
}
