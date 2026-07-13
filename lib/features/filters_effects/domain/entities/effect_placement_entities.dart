import 'package:equatable/equatable.dart';

class BoundingBoxInfoEntity extends Equatable {
  const BoundingBoxInfoEntity({
    required this.fields,
    this.description,
  });

  final List<String> fields;
  final String? description;

  @override
  List<Object?> get props => [fields, description];
}

class LandmarkDefinitionEntity extends Equatable {
  const LandmarkDefinitionEntity({
    required this.key,
    required this.label,
    this.description,
  });

  final String key;
  final String label;
  final String? description;

  @override
  List<Object?> get props => [key, label, description];
}

class FaceDetectionInfoEntity extends Equatable {
  const FaceDetectionInfoEntity({
    this.description,
    this.boundingBox = const BoundingBoxInfoEntity(fields: []),
    this.landmarks = const [],
  });

  final String? description;
  final BoundingBoxInfoEntity boundingBox;
  final List<LandmarkDefinitionEntity> landmarks;

  @override
  List<Object?> get props => [description, boundingBox, landmarks];
}

class AnchorTypeEntity extends Equatable {
  const AnchorTypeEntity({
    required this.key,
    required this.label,
    this.description,
    this.requiresLandmarks = false,
    this.usesFaceBox = false,
  });

  final String key;
  final String label;
  final String? description;
  final bool requiresLandmarks;
  final bool usesFaceBox;

  @override
  List<Object?> get props => [
        key,
        label,
        description,
        requiresLandmarks,
        usesFaceBox,
      ];
}

class SlugPlacementDefaultsEntity extends Equatable {
  const SlugPlacementDefaultsEntity({
    this.anchorType,
    this.anchorLandmarks = const [],
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.fallbackAnchorType,
    this.fallbackOffsetY,
    this.fallbackScaleFactor,
  });

  final String? anchorType;
  final List<String> anchorLandmarks;
  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final String? fallbackAnchorType;
  final double? fallbackOffsetY;
  final double? fallbackScaleFactor;

  @override
  List<Object?> get props => [
        anchorType,
        anchorLandmarks,
        scaleFactor,
        offsetX,
        offsetY,
        landmarkSize,
        fallbackAnchorType,
        fallbackOffsetY,
        fallbackScaleFactor,
      ];
}

class EffectPlacementSchemaEntity extends Equatable {
  const EffectPlacementSchemaEntity({
    required this.version,
    required this.faceDetection,
    required this.anchorTypes,
    required this.landmarks,
    required this.defaultsBySlug,
  });

  final int version;
  final FaceDetectionInfoEntity faceDetection;
  final List<AnchorTypeEntity> anchorTypes;
  final List<LandmarkDefinitionEntity> landmarks;
  final Map<String, SlugPlacementDefaultsEntity> defaultsBySlug;

  AnchorTypeEntity? anchorTypeFor(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final type in anchorTypes) {
      if (type.key == key) return type;
    }
    return null;
  }

  SlugPlacementDefaultsEntity? defaultsForSlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) return null;
    return defaultsBySlug[slug.trim()];
  }

  @override
  List<Object?> get props => [
        version,
        faceDetection,
        anchorTypes,
        landmarks,
        defaultsBySlug,
      ];
}

/// Strongly typed placement fields for effect create/update payloads.
class EffectPlacementSettingsEntity extends Equatable {
  const EffectPlacementSettingsEntity({
    this.anchorType,
    this.anchorLandmarks = const [],
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.fallbackAnchorType,
    this.fallbackOffsetY,
    this.fallbackScaleFactor,
  });

  static const empty = EffectPlacementSettingsEntity();

  final String? anchorType;
  final List<String> anchorLandmarks;
  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final String? fallbackAnchorType;
  final double? fallbackOffsetY;
  final double? fallbackScaleFactor;

  bool get isScreen => anchorType == CameraEffectAnchorTypeApi.screen;

  EffectPlacementSettingsEntity copyWith({
    String? anchorType,
    List<String>? anchorLandmarks,
    double? scaleFactor,
    double? offsetX,
    double? offsetY,
    double? landmarkSize,
    String? fallbackAnchorType,
    double? fallbackOffsetY,
    double? fallbackScaleFactor,
    bool clearAnchorType = false,
    bool clearAnchorLandmarks = false,
    bool clearScaleFactor = false,
    bool clearOffsetX = false,
    bool clearOffsetY = false,
    bool clearLandmarkSize = false,
    bool clearFallbackAnchorType = false,
    bool clearFallbackOffsetY = false,
    bool clearFallbackScaleFactor = false,
  }) {
    return EffectPlacementSettingsEntity(
      anchorType: clearAnchorType ? null : (anchorType ?? this.anchorType),
      anchorLandmarks: clearAnchorLandmarks
          ? const []
          : (anchorLandmarks ?? this.anchorLandmarks),
      scaleFactor:
          clearScaleFactor ? null : (scaleFactor ?? this.scaleFactor),
      offsetX: clearOffsetX ? null : (offsetX ?? this.offsetX),
      offsetY: clearOffsetY ? null : (offsetY ?? this.offsetY),
      landmarkSize:
          clearLandmarkSize ? null : (landmarkSize ?? this.landmarkSize),
      fallbackAnchorType: clearFallbackAnchorType
          ? null
          : (fallbackAnchorType ?? this.fallbackAnchorType),
      fallbackOffsetY:
          clearFallbackOffsetY ? null : (fallbackOffsetY ?? this.fallbackOffsetY),
      fallbackScaleFactor: clearFallbackScaleFactor
          ? null
          : (fallbackScaleFactor ?? this.fallbackScaleFactor),
    );
  }

  EffectPlacementSettingsEntity mergeDefaults(
    SlugPlacementDefaultsEntity defaults,
  ) {
    return copyWith(
      anchorType: defaults.anchorType ?? anchorType,
      anchorLandmarks: defaults.anchorLandmarks.isNotEmpty
          ? defaults.anchorLandmarks
          : anchorLandmarks,
      scaleFactor: defaults.scaleFactor ?? scaleFactor,
      offsetX: defaults.offsetX ?? offsetX,
      offsetY: defaults.offsetY ?? offsetY,
      landmarkSize: defaults.landmarkSize ?? landmarkSize,
      fallbackAnchorType: defaults.fallbackAnchorType ?? fallbackAnchorType,
      fallbackOffsetY: defaults.fallbackOffsetY ?? fallbackOffsetY,
      fallbackScaleFactor: defaults.fallbackScaleFactor ?? fallbackScaleFactor,
    );
  }

  Map<String, dynamic> toCreateJson({required bool includePlacement}) {
    if (!includePlacement) return const {};
    final json = <String, dynamic>{};
    if (anchorType != null && anchorType!.isNotEmpty) {
      json['anchorType'] = CameraEffectAnchorTypeApi.forApi(anchorType!);
    }
    if (anchorLandmarks.isNotEmpty) {
      json['anchorLandmarks'] = anchorLandmarks;
    }
    if (scaleFactor != null) json['scaleFactor'] = scaleFactor;
    if (offsetX != null) json['offsetX'] = offsetX;
    if (offsetY != null) json['offsetY'] = offsetY;
    if (landmarkSize != null) json['landmarkSize'] = landmarkSize;
    if (fallbackAnchorType != null && fallbackAnchorType!.isNotEmpty) {
      json['fallbackAnchorType'] =
          CameraEffectAnchorTypeApi.forApi(fallbackAnchorType!);
    }
    if (fallbackOffsetY != null) json['fallbackOffsetY'] = fallbackOffsetY;
    if (fallbackScaleFactor != null) {
      json['fallbackScaleFactor'] = fallbackScaleFactor;
    }
    return json;
  }

  Map<String, dynamic> toUpdateJson({
    required EffectPlacementSettingsEntity? baseline,
    bool clearAnchorLandmarks = false,
  }) {
    final json = <String, dynamic>{};
    if (clearAnchorLandmarks) {
      json['anchorLandmarks'] = null;
    } else if (anchorLandmarks != baseline?.anchorLandmarks) {
      json['anchorLandmarks'] =
          anchorLandmarks.isEmpty ? null : anchorLandmarks;
    }
    if (anchorType != baseline?.anchorType) {
      json['anchorType'] = anchorType == null || anchorType!.isEmpty
          ? null
          : CameraEffectAnchorTypeApi.forApi(anchorType!);
    }
    if (scaleFactor != baseline?.scaleFactor) json['scaleFactor'] = scaleFactor;
    if (offsetX != baseline?.offsetX) json['offsetX'] = offsetX;
    if (offsetY != baseline?.offsetY) json['offsetY'] = offsetY;
    if (landmarkSize != baseline?.landmarkSize) {
      json['landmarkSize'] = landmarkSize;
    }
    if (fallbackAnchorType != baseline?.fallbackAnchorType) {
      json['fallbackAnchorType'] =
          fallbackAnchorType == null || fallbackAnchorType!.isEmpty
              ? null
              : CameraEffectAnchorTypeApi.forApi(fallbackAnchorType!);
    }
    if (fallbackOffsetY != baseline?.fallbackOffsetY) {
      json['fallbackOffsetY'] = fallbackOffsetY;
    }
    if (fallbackScaleFactor != baseline?.fallbackScaleFactor) {
      json['fallbackScaleFactor'] = fallbackScaleFactor;
    }
    return json;
  }

  @override
  List<Object?> get props => [
        anchorType,
        anchorLandmarks,
        scaleFactor,
        offsetX,
        offsetY,
        landmarkSize,
        fallbackAnchorType,
        fallbackOffsetY,
        fallbackScaleFactor,
      ];
}

/// Normalizes anchor type keys between admin request and API response.
abstract final class CameraEffectAnchorTypeApi {
  static const screen = 'screen';
  static const onFace = 'on_face';
  static const coverFace = 'cover_face';
  static const aboveFace = 'above_face';
  static const dualAboveFace = 'dual_above_face';
  static const betweenLandmarks = 'between_landmarks';
  static const onLandmark = 'on_landmark';
  static const onLandmarks = 'on_landmarks';

  static String normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return screen;
    final lower = trimmed.toLowerCase();
    switch (lower) {
      case 'screen':
      case 'on_face':
      case 'cover_face':
      case 'above_face':
      case 'dual_above_face':
      case 'between_landmarks':
      case 'on_landmark':
      case 'on_landmarks':
        return lower;
    }
    final screaming = trimmed.toUpperCase().replaceAll('-', '_');
    switch (screaming) {
      case 'SCREEN':
        return screen;
      case 'ON_FACE':
        return onFace;
      case 'COVER_FACE':
        return coverFace;
      case 'ABOVE_FACE':
        return aboveFace;
      case 'DUAL_ABOVE_FACE':
        return dualAboveFace;
      case 'BETWEEN_LANDMARKS':
        return betweenLandmarks;
      case 'ON_LANDMARK':
        return onLandmark;
      case 'ON_LANDMARKS':
        return onLandmarks;
      default:
        return lower;
    }
  }

  static String forApi(String value) => normalize(value);
}
