import '../../domain/entities/effect_placement_entities.dart';

/// UI visibility rules for placement fields based on anchor type.
abstract final class EffectPlacementVisibility {
  static bool placementEnabled({
    required bool requiresFaceDetection,
    required bool isScreenEffect,
  }) =>
      requiresFaceDetection && !isScreenEffect;

  static bool showAnchorType({
    required bool requiresFaceDetection,
    required bool isScreenEffect,
  }) =>
      placementEnabled(
        requiresFaceDetection: requiresFaceDetection,
        isScreenEffect: isScreenEffect,
      );

  static bool showScaleFactor(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key == CameraEffectAnchorTypeApi.onFace ||
        key == CameraEffectAnchorTypeApi.coverFace ||
        key == CameraEffectAnchorTypeApi.aboveFace ||
        key == CameraEffectAnchorTypeApi.dualAboveFace ||
        key == CameraEffectAnchorTypeApi.betweenLandmarks;
  }

  static bool showOffsetX(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key == CameraEffectAnchorTypeApi.onFace;
  }

  static bool showOffsetY(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key == CameraEffectAnchorTypeApi.onFace ||
        key == CameraEffectAnchorTypeApi.aboveFace ||
        key == CameraEffectAnchorTypeApi.dualAboveFace;
  }

  static bool showLandmarkMultiSelect(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key == CameraEffectAnchorTypeApi.betweenLandmarks ||
        key == CameraEffectAnchorTypeApi.onLandmarks;
  }

  static bool showLandmarkSingleSelect(String? anchorType) {
    return CameraEffectAnchorTypeApi.normalize(anchorType ?? '') ==
        CameraEffectAnchorTypeApi.onLandmark;
  }

  static bool showLandmarkSize(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key == CameraEffectAnchorTypeApi.onLandmark ||
        key == CameraEffectAnchorTypeApi.onLandmarks;
  }

  static bool showFallbackFields(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    return key != CameraEffectAnchorTypeApi.screen && key.isNotEmpty;
  }

  static int landmarkSelectionLimit(String? anchorType) {
    final key = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    if (key == CameraEffectAnchorTypeApi.betweenLandmarks) return 2;
    return 99;
  }

  static bool isSingleLandmarkMode(String? anchorType) =>
      CameraEffectAnchorTypeApi.normalize(anchorType ?? '') ==
      CameraEffectAnchorTypeApi.onLandmark;
}
