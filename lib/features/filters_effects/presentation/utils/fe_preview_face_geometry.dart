import 'dart:math' as math;
import 'dart:ui';

/// Approximate MediaPipe landmark positions on the bundled preview portrait.
abstract final class FePreviewFaceGeometry {
  static const faceCenter = Offset(0.5, 0.38);
  static const faceWidth = 0.34;
  static const faceHeight = 0.30;

  static const landmarks = <int, Offset>{
    33: Offset(0.38, 0.31),
    133: Offset(0.42, 0.31),
    263: Offset(0.62, 0.31),
    362: Offset(0.58, 0.31),
    168: Offset(0.50, 0.36),
    1: Offset(0.50, 0.43),
    10: Offset(0.50, 0.24),
    152: Offset(0.50, 0.52),
    61: Offset(0.42, 0.47),
    291: Offset(0.58, 0.47),
    17: Offset(0.50, 0.47),
  };

  static Offset? landmark(int? index) {
    if (index == null) return null;
    return landmarks[index];
  }

  static Offset resolvePin({
    required Size size,
    required Map<String, dynamic> anchor,
  }) {
    final leftIdx = _readInt(anchor['leftLandmark']) ?? 33;
    final rightIdx = _readInt(anchor['rightLandmark']) ?? 263;
    final anchorIdx = _readInt(anchor['anchorLandmark']) ?? 168;

    final left = landmark(leftIdx) ?? landmarks[33]!;
    final right = landmark(rightIdx) ?? landmarks[263]!;
    final anchorPt = landmark(anchorIdx) ?? landmarks[168]!;
    final noseTip = landmark(1) ?? landmarks[1]!;
    final chin = landmark(152) ?? landmarks[152]!;
    final forehead = landmark(10) ?? landmarks[10]!;
    final mouthLeft = landmark(61) ?? landmarks[61]!;
    final mouthRight = landmark(291) ?? landmarks[291]!;

    final useAveragedEyes = anchor['useAveragedEyes'] == true;
    final eyeMid = useAveragedEyes
        ? Offset((left.dx + right.dx) / 2, (left.dy + right.dy) / 2)
        : anchorPt;

    final pinX = anchor['pinX']?.toString().trim();
    final pinY = anchor['pinY']?.toString().trim();

    final normalizedX = switch (pinX) {
      'nose_bridge' => anchorPt.dx,
      'eye_center' || 'eye_midpoint' => (left.dx + right.dx) / 2,
      'face_center' => faceCenter.dx,
      'mouth_midpoint' => (mouthLeft.dx + mouthRight.dx) / 2,
      _ => anchorPt.dx,
    };

    final normalizedY = switch (pinY) {
      'eye_line' => (left.dy + right.dy) / 2,
      'nose_tip' => noseTip.dy,
      'chin' => chin.dy,
      'anchor' => anchorPt.dy,
      'top_head_offset' => forehead.dy - 0.04,
      'mouth_midpoint' => (mouthLeft.dy + mouthRight.dy) / 2,
      _ => eyeMid.dy,
    };

    return Offset(normalizedX * size.width, normalizedY * size.height);
  }

  static double resolveStickerWidth({
    required Size size,
    required Map<String, dynamic> anchor,
  }) {
    final leftIdx = _readInt(anchor['leftLandmark']) ?? 33;
    final rightIdx = _readInt(anchor['rightLandmark']) ?? 263;
    final left = landmark(leftIdx) ?? landmarks[33]!;
    final right = landmark(rightIdx) ?? landmarks[263]!;
    final eyeSpan = (right.dx - left.dx).abs() * size.width;

    final widthScreenMult = _readDouble(anchor['widthScreenMult']);
    if (widthScreenMult != null) {
      return size.width * (widthScreenMult / 14.0);
    }

    final widthFaceFrac = _readDouble(anchor['widthFaceFrac']);
    if (widthFaceFrac != null) {
      return eyeSpan * widthFaceFrac;
    }

    final widthMinFaceFrac = _readDouble(anchor['widthMinFaceFrac']);
    if (widthMinFaceFrac != null) {
      return size.width * faceWidth * widthMinFaceFrac;
    }

    return math.max(eyeSpan * 1.35, size.width * 0.18);
  }

  static double resolveStickerHeight({
    required Size size,
    required Map<String, dynamic> anchor,
    required double width,
  }) {
    final heightSpanFrac = _readDouble(anchor['heightSpanFrac']);
    if (heightSpanFrac != null) {
      return size.height * faceHeight * heightSpanFrac;
    }
    return width * 0.75;
  }

  static Offset resolvePivotFraction(Map<String, dynamic> anchor) {
    final pivotU = _readDouble(anchor['pivotU']) ?? 0.5;
    final pivotV = _readDouble(anchor['pivotV']) ?? 0.5;
    return Offset(pivotU.clamp(0.0, 1.0), pivotV.clamp(0.0, 1.0));
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
