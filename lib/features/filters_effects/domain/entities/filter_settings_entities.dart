import 'package:equatable/equatable.dart';

/// Slider value range metadata from the schema API.
class FilterSettingValueRangeEntity extends Equatable {
  const FilterSettingValueRangeEntity({
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  final int min;
  final int max;
  final int defaultValue;

  @override
  List<Object?> get props => [min, max, defaultValue];
}

class FilterSettingGroupEntity extends Equatable {
  const FilterSettingGroupEntity({
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

class FilterSettingDefinitionEntity extends Equatable {
  const FilterSettingDefinitionEntity({
    required this.key,
    required this.label,
    required this.group,
    required this.type,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.step,
    this.colorMatrix = false,
    this.clientOnly = false,
    this.description,
  });

  final String key;
  final String label;
  final String group;
  final String type;
  final int min;
  final int max;
  final int defaultValue;
  final int step;
  final bool colorMatrix;
  final bool clientOnly;
  final String? description;

  bool get isBipolar => type == 'bipolar';

  @override
  List<Object?> get props => [
    key,
    label,
    group,
    type,
    min,
    max,
    defaultValue,
    step,
    colorMatrix,
    clientOnly,
    description,
  ];
}

class FilterSettingsSchemaEntity extends Equatable {
  const FilterSettingsSchemaEntity({
    required this.version,
    required this.bipolarRange,
    required this.unipolarRange,
    required this.groups,
    required this.settings,
  });

  final int version;
  final FilterSettingValueRangeEntity bipolarRange;
  final FilterSettingValueRangeEntity unipolarRange;
  final List<FilterSettingGroupEntity> groups;
  final List<FilterSettingDefinitionEntity> settings;

  FilterSettingDefinitionEntity? definitionFor(String key) {
    for (final setting in settings) {
      if (setting.key == key) return setting;
    }
    return null;
  }

  Map<String, int> defaultValues() {
    return {for (final s in settings) s.key: s.defaultValue};
  }

  @override
  List<Object?> get props => [
    version,
    bipolarRange,
    unipolarRange,
    groups,
    settings,
  ];
}

/// Strongly typed filter beauty and adjustment settings.
class FilterSettingsEntity extends Equatable {
  const FilterSettingsEntity({
    this.smooth,
    this.whiten,
    this.brighten,
    this.blush,
    this.lipStrength,
    this.lipTint,
    this.defaultIntensity,
    this.brightness,
    this.contrast,
    this.saturation,
    this.warmth,
    this.values = const {},
  });

  final int? smooth;
  final int? whiten;
  final int? brighten;
  final int? blush;
  final int? lipStrength;
  final String? lipTint;
  final int? defaultIntensity;
  final int? brightness;
  final int? contrast;
  final int? saturation;
  final int? warmth;
  final Map<String, int> values;

  static const empty = FilterSettingsEntity();

  static const defaultSmooth = 55;
  static const defaultWhiten = 0;
  static const defaultBrighten = 0;
  static const defaultBlush = 0;
  static const defaultLipStrength = 0;
  static const defaultLipTint = '#E8527A';
  static const defaultIntensityVal = 70;
  static const defaultBrightness = 50;
  static const defaultContrast = 50;
  static const defaultSaturation = 50;
  static const defaultWarmth = 50;

  factory FilterSettingsEntity.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    final map = <String, int>{};
    json.forEach((k, v) {
      if (v is num) map[k] = v.toInt();
    });

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt().clamp(0, 100);
      return int.tryParse(v.toString())?.clamp(0, 100);
    }

    String? parseHex(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      return str.isNotEmpty ? str : null;
    }

    return FilterSettingsEntity(
      smooth: parseInt(json['smooth']),
      whiten: parseInt(json['whiten']),
      brighten: parseInt(json['brighten']),
      blush: parseInt(json['blush']),
      lipStrength: parseInt(json['lipStrength']),
      lipTint: parseHex(json['lipTint']),
      defaultIntensity: parseInt(json['defaultIntensity']),
      brightness: parseInt(json['brightness']),
      contrast: parseInt(json['contrast']),
      saturation: parseInt(json['saturation']),
      warmth: parseInt(json['warmth']),
      values: map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (smooth != null) 'smooth': smooth,
      if (whiten != null) 'whiten': whiten,
      if (brighten != null) 'brighten': brighten,
      if (blush != null) 'blush': blush,
      if (lipStrength != null) 'lipStrength': lipStrength,
      if (lipTint != null && lipTint!.isNotEmpty) 'lipTint': lipTint,
      if (defaultIntensity != null) 'defaultIntensity': defaultIntensity,
      if (brightness != null) 'brightness': brightness,
      if (contrast != null) 'contrast': contrast,
      if (saturation != null) 'saturation': saturation,
      if (warmth != null) 'warmth': warmth,
      ...values.map((k, v) => MapEntry(k, v)),
    };
  }

  FilterSettingsEntity copyWith({
    int? smooth,
    int? whiten,
    int? brighten,
    int? blush,
    int? lipStrength,
    String? lipTint,
    int? defaultIntensity,
    int? brightness,
    int? contrast,
    int? saturation,
    int? warmth,
    Map<String, int>? values,
    bool clearLipTint = false,
  }) {
    return FilterSettingsEntity(
      smooth: smooth ?? this.smooth,
      whiten: whiten ?? this.whiten,
      brighten: brighten ?? this.brighten,
      blush: blush ?? this.blush,
      lipStrength: lipStrength ?? this.lipStrength,
      lipTint: clearLipTint ? null : (lipTint ?? this.lipTint),
      defaultIntensity: defaultIntensity ?? this.defaultIntensity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      values: values ?? this.values,
    );
  }

  @override
  List<Object?> get props => [
    smooth,
    whiten,
    brighten,
    blush,
    lipStrength,
    lipTint,
    defaultIntensity,
    brightness,
    contrast,
    saturation,
    warmth,
    values,
  ];
}
