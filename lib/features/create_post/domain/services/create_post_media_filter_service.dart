import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/camera_engine_filter_look.dart';
import '../entities/create_post_entity.dart';
import '../entities/create_post_media_filter_entity.dart';
import '../entities/local_media_file.dart';

/// Applies non-destructive image filters before upload; videos use preview-only.
class CreatePostMediaFilterService {
  const CreatePostMediaFilterService();

  List<double> buildColorMatrix(CreatePostMediaFilterEntity filter) {
    if (!filter.hasCustomAdjustments) {
      return CameraEngineFilterLook.identityMatrix;
    }

    final brightnessBias = filter.brightness * 25 + filter.exposure * 15;
    final contrast = 1 + filter.contrast * 0.5;
    final saturation = 1 + filter.saturation * 0.5;
    final warmth = filter.warmth * 0.15;

    final rScale = contrast * (1 + warmth);
    final bScale = contrast * (1 - warmth * 0.6);

    return _matrix(
      rR: rScale,
      gG: contrast,
      bB: bScale,
      rBias: brightnessBias,
      gBias: brightnessBias,
      bBias: brightnessBias - warmth * 8,
      sat: saturation.clamp(0, 3),
    );
  }

  ColorFilter? catalogColorFilterFor(CreatePostMediaFilterEntity filter) {
    final matrix = filter.catalogColorMatrix;
    if (matrix == null || matrix.length < 20) return null;
    return ColorFilter.matrix(matrix.take(20).toList());
  }

  ColorFilter? customColorFilterFor(CreatePostMediaFilterEntity filter) {
    if (!filter.hasCustomAdjustments) return null;
    return ColorFilter.matrix(buildColorMatrix(filter));
  }

  ColorFilter? colorFilterFor(CreatePostMediaFilterEntity filter) {
    return customColorFilterFor(filter) ?? catalogColorFilterFor(filter);
  }

  /// Ordered color matrices for stacking (catalog then custom), used by web
  /// CSS `feColorMatrix` on video elements where [ColorFiltered] is ignored.
  List<List<double>> colorMatricesFor(CreatePostMediaFilterEntity filter) {
    final matrices = <List<double>>[];
    final catalog = filter.catalogColorMatrix;
    if (catalog != null && catalog.length >= 20) {
      matrices.add(catalog.take(20).toList(growable: false));
    }
    if (filter.hasCustomAdjustments) {
      matrices.add(buildColorMatrix(filter));
    }
    return matrices;
  }

  Widget buildFilteredPreview({
    required Widget child,
    required CreatePostMediaFilterEntity filter,
  }) {
    var result = child;
    final catalog = catalogColorFilterFor(filter);
    if (catalog != null) {
      result = ColorFiltered(colorFilter: catalog, child: result);
    }
    final custom = customColorFilterFor(filter);
    if (custom != null) {
      result = ColorFiltered(colorFilter: custom, child: result);
    }
    return result;
  }

  Future<Uint8List> applyToImageBytes(
    Uint8List bytes,
    CreatePostMediaFilterEntity filter,
  ) async {
    if (filter.isNeutral) return bytes;

    final catalog = catalogColorFilterFor(filter);
    final custom = customColorFilterFor(filter);
    if (catalog == null && custom == null) return bytes;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = custom ?? catalog;
      canvas.drawImage(image, Offset.zero, paint);
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

  Future<CreatePostEntity> applyFiltersToImages(CreatePostEntity form) async {
    final updated = <LocalMediaFile>[];
    for (final file in form.localMedia) {
      if (file.mediaType == 'IMAGE' && file.hasFilter) {
        final filteredBytes = await applyToImageBytes(file.bytes, file.filter);
        updated.add(file.copyWith(bytes: filteredBytes));
      } else {
        updated.add(file);
      }
    }

    var result = form.copyWith(localMedia: updated);
    if (result.thumbnailBytes != null && result.thumbnailBytes!.isNotEmpty) {
      final filteredVideos = result.localMedia.where((m) => m.mediaType == 'VIDEO' && m.hasFilter);
      if (filteredVideos.isNotEmpty) {
        final filteredThumb = await applyToImageBytes(
          result.thumbnailBytes!,
          filteredVideos.first.filter,
        );
        result = result.copyWith(thumbnailBytes: filteredThumb);
      }
    }
    return result;
  }

  static List<double> _matrix({
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
}
