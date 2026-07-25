import '../../../../core/utils/camera_engine_filter_look.dart';
import '../../domain/entities/filter_settings_entities.dart';

/// Approximates the server-side matrix filter look from slider adjustments.
List<double>? buildFePreviewMatrixFromAdjustments(Map<String, int> adjustments) {
  if (adjustments.isEmpty) return null;

  final brightness = (adjustments['brightness'] ?? 0) / 100.0;
  final contrast = 1 + (adjustments['contrast'] ?? 0) / 100.0 * 0.5;
  final saturation = 1 + (adjustments['saturation'] ?? 0) / 100.0 * 0.5;
  final warmth = (adjustments['warmth'] ?? 0) / 100.0 * 0.15;
  final exposure = (adjustments['exposure'] ?? 0) / 100.0;

  final hasEffect = adjustments.values.any((value) => value != 0);
  if (!hasEffect) return null;

  final brightnessBias = brightness * 25 + exposure * 15;
  final rScale = contrast * (1 + warmth);
  final bScale = contrast * (1 - warmth * 0.6);

  return cameraEngineFilterMatrix(
    rR: rScale,
    gG: contrast,
    bB: bScale,
    rBias: brightnessBias,
    gBias: brightnessBias,
    bBias: brightnessBias - warmth * 8,
    sat: saturation.clamp(0, 3),
  );
}

/// Approximates visual image transformation from FilterSettingsEntity beauty & color sliders.
List<double>? buildFePreviewMatrixFromFilterSettings(FilterSettingsEntity settings) {
  final brightnessVal = settings.brightness ?? FilterSettingsEntity.defaultBrightness;
  final contrastVal = settings.contrast ?? FilterSettingsEntity.defaultContrast;
  final saturationVal = settings.saturation ?? FilterSettingsEntity.defaultSaturation;
  final warmthVal = settings.warmth ?? FilterSettingsEntity.defaultWarmth;
  final whitenVal = settings.whiten ?? FilterSettingsEntity.defaultWhiten;
  final brightenVal = settings.brighten ?? FilterSettingsEntity.defaultBrighten;
  final blushVal = settings.blush ?? FilterSettingsEntity.defaultBlush;
  final smoothVal = settings.smooth ?? FilterSettingsEntity.defaultSmooth;
  final intensityVal = settings.defaultIntensity ?? FilterSettingsEntity.defaultIntensityVal;

  final intensityFactor = intensityVal / 70.0;

  final brightness = ((brightnessVal - 50) / 50.0 + (brightenVal / 180.0) + (whitenVal / 220.0)) * intensityFactor;
  final contrast = 1.0 + ((contrastVal - 50) / 50.0 * 0.4) * intensityFactor;
  final saturation = 1.0 + ((saturationVal - 50) / 50.0 * 0.8) * intensityFactor;
  final warmth = ((warmthVal - 50) / 50.0 * 0.25 + (blushVal / 250.0)) * intensityFactor;
  final smoothSoftness = (smoothVal / 100.0) * 8.0;

  final brightnessBias = brightness * 35.0 + smoothSoftness;
  final rScale = contrast * (1.0 + warmth);
  final bScale = contrast * (1.0 - warmth * 0.6);

  return cameraEngineFilterMatrix(
    rR: rScale,
    gG: contrast,
    bB: bScale,
    rBias: brightnessBias,
    gBias: brightnessBias,
    bBias: brightnessBias - warmth * 12.0,
    sat: saturation.clamp(0.0, 3.0),
  );
}

List<double>? resolveFePreviewFilterMatrix({
  required String? renderType,
  FilterSettingsEntity? filterSettings,
  Map<String, int> adjustments = const {},
  List<double> colorMatrix = const [],
}) {
  if (filterSettings != null) {
    final fromSettings = buildFePreviewMatrixFromFilterSettings(filterSettings);
    if (fromSettings != null) return fromSettings;
  }

  final fromAdjustments = buildFePreviewMatrixFromAdjustments(adjustments);
  if (fromAdjustments != null) return fromAdjustments;
  if (colorMatrix.length == 20) return colorMatrix;
  return null;
}
