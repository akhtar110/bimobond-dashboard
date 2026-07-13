import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/camera_engine_filter_look.dart';
import '../../domain/entities/filter_settings_entities.dart';

/// Dashboard-only visual simulation for filter slider adjustments.
///
/// Always derives the look from [filterSettings] (same for create, edit, and
/// list preview). Saved server `colorMatrix` is intentionally not used here so
/// the preview never jumps between two different pipelines.
class FilterSettingsPreviewLook {
  const FilterSettingsPreviewLook({
    this.colorMatrix,
    this.warmthOverlay,
    this.warmthOpacity = 0,
    this.skinToneOverlay,
    this.skinToneOpacity = 0,
    this.brightenOverlay,
    this.brightenOpacity = 0,
    this.vignette = 0,
    this.blurSigma = 0,
    this.fadeOpacity = 0,
    this.grainOpacity = 0,
    this.sharpenOpacity = 0,
  });

  final List<double>? colorMatrix;
  final Color? warmthOverlay;
  final double warmthOpacity;
  final Color? skinToneOverlay;
  final double skinToneOpacity;
  final Color? brightenOverlay;
  final double brightenOpacity;
  final double vignette;
  final double blurSigma;
  final double fadeOpacity;
  final double grainOpacity;
  final double sharpenOpacity;

  bool get hasEffect =>
      (colorMatrix != null && !_isIdentityMatrix(colorMatrix!)) ||
      (warmthOverlay != null && warmthOpacity > 0) ||
      (skinToneOverlay != null && skinToneOpacity > 0) ||
      (brightenOverlay != null && brightenOpacity > 0) ||
      vignette > 0 ||
      blurSigma > 0 ||
      fadeOpacity > 0 ||
      grainOpacity > 0 ||
      sharpenOpacity > 0;
}

/// Merges schema defaults with stored values so sparse API maps match editor maps.
FilterSettingsEntity normalizeFilterSettingsForPreview(
  FilterSettingsEntity settings,
  FilterSettingsSchemaEntity schema,
) {
  final merged = Map<String, int>.from(schema.defaultValues());
  merged.addAll(settings.values);
  return FilterSettingsEntity(merged);
}

int _setting(FilterSettingsEntity settings, String key, int fallback) =>
    settings.values[key] ?? fallback;

double _bipolar(FilterSettingsEntity settings, String key) =>
    _setting(settings, key, 0) / 100.0;

double _unipolar(FilterSettingsEntity settings, String key) =>
    _setting(settings, key, 0) / 100.0;

/// Builds a preview look solely from current slider values + schema defaults.
///
/// Same inputs always produce the same look in create, edit, and list preview.
FilterSettingsPreviewLook filterSettingsPreviewLook({
  required FilterSettingsEntity filterSettings,
  required FilterSettingsSchemaEntity schema,
  String? engineKey,
}) {
  final settings = normalizeFilterSettingsForPreview(filterSettings, schema);

  final skinSmooth = _unipolar(settings, 'skinSmooth');
  final blur = _unipolar(settings, 'blur');
  final skinTone = _bipolar(settings, 'skinTone');
  final eyeBrighten = _unipolar(settings, 'eyeBrighten');
  final teethWhiten = _unipolar(settings, 'teethWhiten');
  final sharpen = _unipolar(settings, 'sharpen');
  final clarity = _unipolar(settings, 'clarity');
  final grain = _unipolar(settings, 'grain');
  final dehaze = _unipolar(settings, 'dehaze');
  final warmth = _bipolar(settings, 'warmth');

  return FilterSettingsPreviewLook(
    colorMatrix: _matrixFromSettings(settings),
    vignette: _unipolar(settings, 'vignette'),
    blurSigma: (blur * 4) + (skinSmooth * 3.2),
    fadeOpacity: _bipolar(settings, 'fade').clamp(0.0, 1.0) * 0.35,
    // Warmth is already in the matrix; keep a light wash for visibility only.
    warmthOverlay: _warmthOverlayColor(warmth),
    warmthOpacity: warmth.abs() * 0.1,
    skinToneOverlay: _skinToneOverlayColor(skinTone),
    skinToneOpacity: skinTone.abs() * 0.16,
    brightenOverlay: (eyeBrighten > 0.01 || teethWhiten > 0.01)
        ? Colors.white
        : null,
    brightenOpacity:
        (eyeBrighten * 0.12 + teethWhiten * 0.1).clamp(0.0, 0.28),
    grainOpacity: grain * 0.22,
    sharpenOpacity: ((sharpen + clarity + dehaze) * 0.12).clamp(0.0, 0.35),
  );
}

Color? _warmthOverlayColor(double warmth) {
  if (warmth.abs() < 0.01) return null;
  return warmth > 0
      ? const Color(0xFFFF9800)
      : const Color(0xFF42A5F5);
}

Color? _skinToneOverlayColor(double skinTone) {
  if (skinTone.abs() < 0.01) return null;
  return skinTone > 0
      ? const Color(0xFFE8A87C)
      : const Color(0xFFC4A484);
}

List<double> _matrixFromSettings(FilterSettingsEntity settings) {
  final brightness = _bipolar(settings, 'brightness');
  final contrast = _bipolar(settings, 'contrast');
  final saturation = _bipolar(settings, 'saturation');
  final exposure = _bipolar(settings, 'exposure');
  final warmth = _bipolar(settings, 'warmth');
  final tint = _bipolar(settings, 'tint');
  final highlights = _bipolar(settings, 'highlights');
  final shadows = _bipolar(settings, 'shadows');
  final whites = _bipolar(settings, 'whites');
  final blacks = _bipolar(settings, 'blacks');
  final vibrance = _bipolar(settings, 'vibrance');
  final hue = _bipolar(settings, 'hue');

  final contrastScale = 1.0 + contrast * 0.45 + whites * 0.08 - blacks * 0.06;
  final satScale = 1.0 + saturation * 0.65 + vibrance * 0.4;
  final bias = brightness * 28 +
      exposure * 22 +
      highlights * 8 +
      shadows * 6 +
      whites * 6 -
      blacks * 8;
  final hueShift = hue * 0.18;

  return cameraEngineFilterMatrix(
    rR: contrastScale + warmth * 0.12,
    rG: hueShift,
    rB: -hueShift * 0.5,
    gR: -hueShift * 0.4,
    gG: contrastScale + tint * -0.06,
    gB: hueShift * 0.3,
    bR: hueShift * 0.2,
    bG: -hueShift * 0.3,
    bB: contrastScale - warmth * 0.12 + tint * 0.06,
    rBias: bias + warmth * 14,
    gBias: bias + tint * -10,
    bBias: bias - warmth * 14 + tint * 10,
    sat: satScale,
  );
}

bool _isIdentityMatrix(List<double> matrix) {
  if (matrix.length < 20) return true;
  const identity = CameraEngineFilterLook.identityMatrix;
  for (var i = 0; i < 20; i++) {
    if ((matrix[i] - identity[i]).abs() > 0.001) return false;
  }
  return true;
}

Widget applyFilterSettingsPreviewLook({
  required Widget child,
  required FilterSettingsPreviewLook look,
}) {
  if (!look.hasEffect) return child;

  Widget result = child;

  if (look.colorMatrix != null && !_isIdentityMatrix(look.colorMatrix!)) {
    result = ColorFiltered(
      colorFilter: ColorFilter.matrix(look.colorMatrix!),
      child: result,
    );
  }

  if (look.warmthOverlay != null && look.warmthOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: look.warmthOverlay!.withValues(alpha: look.warmthOpacity),
        ),
      ],
    );
  }

  if (look.skinToneOverlay != null && look.skinToneOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: look.skinToneOverlay!.withValues(alpha: look.skinToneOpacity),
        ),
      ],
    );
  }

  if (look.brightenOverlay != null && look.brightenOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: look.brightenOverlay!.withValues(alpha: look.brightenOpacity),
        ),
      ],
    );
  }

  if (look.fadeOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: Colors.grey.withValues(alpha: look.fadeOpacity),
        ),
      ],
    );
  }

  if (look.grainOpacity > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        ColoredBox(
          color: Colors.black.withValues(alpha: look.grainOpacity * 0.35),
        ),
        ColoredBox(
          color: Colors.white.withValues(alpha: look.grainOpacity * 0.15),
        ),
      ],
    );
  }

  if (look.sharpenOpacity > 0) {
    result = ColorFiltered(
      colorFilter: ColorFilter.matrix(
        cameraEngineFilterMatrix(
          rR: 1 + look.sharpenOpacity * 0.35,
          gG: 1 + look.sharpenOpacity * 0.35,
          bB: 1 + look.sharpenOpacity * 0.35,
          rBias: -look.sharpenOpacity * 8,
          gBias: -look.sharpenOpacity * 8,
          bBias: -look.sharpenOpacity * 8,
        ),
      ),
      child: result,
    );
  }

  if (look.vignette > 0) {
    result = Stack(
      fit: StackFit.expand,
      children: [
        result,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.92,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: look.vignette * 0.65),
              ],
            ),
          ),
        ),
      ],
    );
  }

  if (look.blurSigma > 0.5) {
    result = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: look.blurSigma,
        sigmaY: look.blurSigma,
      ),
      child: result,
    );
  }

  return result;
}
