import '../../../../core/utils/camera_engine_filter_look.dart';
import '../../domain/entities/filters_effects_entities.dart';

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

List<double>? resolveFePreviewFilterMatrix({
  required String? renderType,
  Map<String, int> adjustments = const {},
  List<double> colorMatrix = const [],
}) {
  if (!CameraFilterRenderTypeApi.isMatrix(renderType ?? '')) return null;

  final fromAdjustments = buildFePreviewMatrixFromAdjustments(adjustments);
  if (fromAdjustments != null) return fromAdjustments;
  if (colorMatrix.length == 20) return colorMatrix;
  return null;
}
