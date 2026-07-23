import '../../domain/entities/effect_placement_entities.dart';

class EffectPlacementSchemaModel extends EffectPlacementSchemaEntity {
  const EffectPlacementSchemaModel({
    required super.version,
    required super.faceDetection,
    required super.anchorTypes,
    required super.landmarks,
    required super.defaultsBySlug,
  });

  factory EffectPlacementSchemaModel.fromJson(Map<String, dynamic> json) {
    final faceDetectionRaw =
        json['faceDetection'] as Map<String, dynamic>? ?? {};
    final boundingBoxRaw =
        faceDetectionRaw['boundingBox'] as Map<String, dynamic>? ?? {};
    final faceLandmarks = (faceDetectionRaw['landmarks'] as List? ?? [])
        .map((e) => _landmarkFromJson(e as Map<String, dynamic>))
        .toList();

    final schemaLandmarks = (json['landmarks'] as List? ?? [])
        .map((e) => _landmarkFromJson(e as Map<String, dynamic>))
        .toList();

    final anchorTypes = (json['anchorTypes'] as List? ?? [])
        .map(
          (e) => AnchorTypeEntity(
            key: CameraEffectAnchorTypeApi.normalize(
              e['key']?.toString() ?? '',
            ),
            label: e['label']?.toString() ?? '',
            description: e['description']?.toString(),
            requiresLandmarks: e['requiresLandmarks'] == true,
            usesFaceBox: e['usesFaceBox'] == true,
          ),
        )
        .toList();

    final defaultsRaw = json['defaultsBySlug'] as Map<String, dynamic>? ?? {};
    final defaults = <String, SlugPlacementDefaultsEntity>{};
    for (final entry in defaultsRaw.entries) {
      defaults[entry.key] = _defaultsFromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return EffectPlacementSchemaModel(
      version: _int(json['version']),
      faceDetection: FaceDetectionInfoEntity(
        description: faceDetectionRaw['description']?.toString(),
        boundingBox: BoundingBoxInfoEntity(
          fields: (boundingBoxRaw['fields'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
          description: boundingBoxRaw['description']?.toString(),
        ),
        landmarks: faceLandmarks,
      ),
      anchorTypes: anchorTypes,
      landmarks: schemaLandmarks.isNotEmpty ? schemaLandmarks : faceLandmarks,
      defaultsBySlug: defaults,
    );
  }
}

LandmarkDefinitionEntity _landmarkFromJson(Map<String, dynamic> json) {
  return LandmarkDefinitionEntity(
    key: json['key']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    description: json['description']?.toString(),
  );
}

SlugPlacementDefaultsEntity _defaultsFromJson(Map<String, dynamic> json) {
  return SlugPlacementDefaultsEntity(
    anchorType: json['anchorType'] == null
        ? null
        : CameraEffectAnchorTypeApi.normalize(json['anchorType'].toString()),
    anchorLandmarks: _stringList(json['anchorLandmarks']),
    scaleFactor: _double(json['scaleFactor']),
    offsetX: _double(json['offsetX']),
    offsetY: _double(json['offsetY']),
    landmarkSize: _double(json['landmarkSize']),
    fallbackAnchorType: json['fallbackAnchorType'] == null
        ? null
        : CameraEffectAnchorTypeApi.normalize(
            json['fallbackAnchorType'].toString(),
          ),
    fallbackOffsetY: _double(json['fallbackOffsetY']),
    fallbackScaleFactor: _double(json['fallbackScaleFactor']),
  );
}

List<String> parseEffectAnchorLandmarks(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).toList();
}

List<String> _stringList(dynamic raw) => parseEffectAnchorLandmarks(raw);

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
