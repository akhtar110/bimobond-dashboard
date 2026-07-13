import 'package:flutter/material.dart';

import '../../domain/entities/effect_placement_entities.dart';

/// Dashboard-only layout hints for effect overlay preview (not real AR).
class EffectPlacementPreviewLayout {
  const EffectPlacementPreviewLayout({
    required this.primaryAlignment,
    this.secondaryAlignment,
    this.sizeFactor = 1,
    this.coverFace = false,
  });

  final Alignment primaryAlignment;
  final Alignment? secondaryAlignment;
  final double sizeFactor;
  final bool coverFace;

  static EffectPlacementPreviewLayout forPlacement({
    required String? anchorType,
    double? scaleFactor,
    double? offsetX,
    double? offsetY,
    double? landmarkSize,
    List<String> anchorLandmarks = const [],
  }) {
    final anchor = CameraEffectAnchorTypeApi.normalize(anchorType ?? '');
    final scale = scaleFactor ?? 1.0;
    final ox = (offsetX ?? 0).clamp(-1.0, 1.0);
    final oy = (offsetY ?? 0).clamp(-1.0, 1.0);
    const faceY = -0.22;

    switch (anchor) {
      case CameraEffectAnchorTypeApi.screen:
        return const EffectPlacementPreviewLayout(
          primaryAlignment: Alignment.center,
          sizeFactor: 1,
        );
      case CameraEffectAnchorTypeApi.aboveFace:
        return EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(ox * 0.35, faceY + oy * 0.5 - 0.2),
          sizeFactor: scale,
        );
      case CameraEffectAnchorTypeApi.dualAboveFace:
        return EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(0.28 + ox * 0.2, faceY + oy * 0.5 - 0.22),
          secondaryAlignment: Alignment(-0.28 + ox * 0.2, faceY + oy * 0.5 - 0.22),
          sizeFactor: scale * 0.85,
        );
      case CameraEffectAnchorTypeApi.coverFace:
        return EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(ox * 0.2, faceY + oy * 0.15),
          sizeFactor: scale * 1.2,
          coverFace: true,
        );
      case CameraEffectAnchorTypeApi.betweenLandmarks:
        return EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(ox * 0.2, faceY - 0.04 + oy * 0.2),
          sizeFactor: scale * 0.75,
        );
      case CameraEffectAnchorTypeApi.onLandmark:
        return EffectPlacementPreviewLayout(
          primaryAlignment: _landmarkAlignment(
            anchorLandmarks.isNotEmpty ? anchorLandmarks.first : 'leftEye',
            faceY,
          ),
          sizeFactor: (landmarkSize ?? 0.2) * 3.5,
        );
      case CameraEffectAnchorTypeApi.onLandmarks:
        if (anchorLandmarks.length >= 2) {
          return EffectPlacementPreviewLayout(
            primaryAlignment: _landmarkAlignment(anchorLandmarks[0], faceY),
            secondaryAlignment: _landmarkAlignment(anchorLandmarks[1], faceY),
            sizeFactor: (landmarkSize ?? 0.2) * 3.5,
          );
        }
        return EffectPlacementPreviewLayout(
          primaryAlignment: _landmarkAlignment(
            anchorLandmarks.isNotEmpty ? anchorLandmarks.first : 'leftEar',
            faceY,
          ),
          sizeFactor: (landmarkSize ?? 0.2) * 3.5,
        );
      default:
        return EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(ox * 0.35, faceY + oy * 0.35),
          sizeFactor: scale * 0.85,
        );
    }
  }

  static Alignment _landmarkAlignment(String key, double faceY) {
    return switch (key) {
      'rightEye' => Alignment(0.18, faceY - 0.06),
      'noseBase' => Alignment(0, faceY + 0.02),
      'mouth' => Alignment(0, faceY + 0.14),
      'leftEar' => Alignment(-0.32, faceY - 0.02),
      'rightEar' => Alignment(0.32, faceY - 0.02),
      _ => Alignment(-0.18, faceY - 0.06),
    };
  }
}
