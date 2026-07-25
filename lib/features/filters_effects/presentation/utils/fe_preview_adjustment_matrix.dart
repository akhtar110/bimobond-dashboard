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

  final hasEffect = brightnessVal != 50 ||
      contrastVal != 50 ||
      saturationVal != 50 ||
      warmthVal != 50 ||
      whitenVal != 0 ||
      brightenVal != 0 ||
      blushVal != 0;

  if (!hasEffect) return null;

  final brightness = (brightnessVal - 50) / 50.0 + (brightenVal / 200.0) + (whitenVal / 250.0);
  final contrast = 1.0 + (contrastVal - 50) / 50.0 * 0.5;
  final saturation = saturationVal / 50.0;
  final warmth = (warmthVal - 50) / 50.0 * 0.2 + (blushVal / 300.0);

  final brightnessBias = brightness * 35;
  final rScale = contrast * (1 + warmth);
  final bScale = contrast * (1 - warmth * 0.6);

  return cameraEngineFilterMatrix(
    rR: rScale,
    gG: contrast,
    bB: bScale,
    rBias: brightnessBias,
    gBias: brightnessBias,
    bBias: brightnessBias - warmth * 10,
    sat: saturation.clamp(0, 3),
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
