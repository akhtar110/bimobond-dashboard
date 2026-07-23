import 'package:equatable/equatable.dart';

/// Structured sticker anchor fields mapped to the mobile render engine JSON.
///
/// Unknown keys from the API are preserved in [extras] so seeded anchors are
/// not lost when editing a subset of fields in the admin UI.
class EffectAnchorFormData extends Equatable {
  const EffectAnchorFormData({
    this.pinX,
    this.pinY,
    this.leftLandmark,
    this.rightLandmark,
    this.anchorLandmark,
    this.widthScreenMult,
    this.widthFaceFrac,
    this.widthMinFaceFrac,
    this.heightSpanFrac,
    this.pivotU,
    this.pivotV,
    this.useAveragedEyes,
    this.scaleFromFaceBox,
    this.extras = const {},
  });

  static const empty = EffectAnchorFormData();

  /// Recommended defaults from the Camera Studio `glasses` seed effect.
  static const glassesPreset = EffectAnchorFormData(
    pinX: 'nose_bridge',
    pinY: 'eye_line',
    leftLandmark: '33',
    rightLandmark: '263',
    anchorLandmark: '168',
    widthScreenMult: '3.5',
    widthMinFaceFrac: '0.7',
    pivotU: '0.5',
    pivotV: '0.5',
    useAveragedEyes: true,
  );

  static const scaleMin = 0.5;
  static const scaleMax = 8.0;
  static const scaleDefault = 3.5;
  static const fracMin = 0.05;
  static const fracMax = 2.0;
  static const pivotMin = 0.0;
  static const pivotMax = 1.0;

  static const _knownKeys = {
    'pinX',
    'pinY',
    'leftLandmark',
    'rightLandmark',
    'anchorLandmark',
    'widthScreenMult',
    'widthFaceFrac',
    'widthMinFaceFrac',
    'heightSpanFrac',
    'pivotU',
    'pivotV',
    'useAveragedEyes',
    'scaleFromFaceBox',
  };

  final String? pinX;
  final String? pinY;
  final String? leftLandmark;
  final String? rightLandmark;
  final String? anchorLandmark;
  final String? widthScreenMult;
  final String? widthFaceFrac;
  final String? widthMinFaceFrac;
  final String? heightSpanFrac;
  final String? pivotU;
  final String? pivotV;
  final bool? useAveragedEyes;
  final bool? scaleFromFaceBox;
  final Map<String, dynamic> extras;

  factory EffectAnchorFormData.fromMap(Map<String, dynamic> map) {
    String? readString(String key) {
      final value = map[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    String? readNumeric(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toString();
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    bool? readBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      final text = value.toString().trim().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
      return null;
    }

    final extras = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!_knownKeys.contains(entry.key)) {
        extras[entry.key] = entry.value;
      }
    }

    return EffectAnchorFormData(
      pinX: readString('pinX'),
      pinY: readString('pinY'),
      leftLandmark: readNumeric(map['leftLandmark']),
      rightLandmark: readNumeric(map['rightLandmark']),
      anchorLandmark: readNumeric(map['anchorLandmark']),
      widthScreenMult: readNumeric(map['widthScreenMult']),
      widthFaceFrac: readNumeric(map['widthFaceFrac']),
      widthMinFaceFrac: readNumeric(map['widthMinFaceFrac']),
      heightSpanFrac: readNumeric(map['heightSpanFrac']),
      pivotU: readNumeric(map['pivotU']),
      pivotV: readNumeric(map['pivotV']),
      useAveragedEyes: readBool(map['useAveragedEyes']),
      scaleFromFaceBox: readBool(map['scaleFromFaceBox']),
      extras: extras,
    );
  }

  int? get parsedLeftLandmark => _parseInt(leftLandmark);

  int? get parsedRightLandmark => _parseInt(rightLandmark);

  int? get parsedAnchorLandmark => _parseInt(anchorLandmark);

  double? get parsedWidthScreenMult => _parseDouble(widthScreenMult);

  double? get parsedWidthFaceFrac => _parseDouble(widthFaceFrac);

  double? get parsedWidthMinFaceFrac => _parseDouble(widthMinFaceFrac);

  double? get parsedHeightSpanFrac => _parseDouble(heightSpanFrac);

  double? get parsedPivotU => _parseDouble(pivotU);

  double? get parsedPivotV => _parseDouble(pivotV);

  double get resolvedScale {
    final parsed = parsedWidthScreenMult;
    if (parsed == null) return scaleDefault;
    return parsed.clamp(scaleMin, scaleMax);
  }

  double get resolvedWidthFaceFrac {
    final parsed = parsedWidthFaceFrac;
    if (parsed == null) return 1.0;
    return parsed.clamp(fracMin, fracMax);
  }

  double get resolvedWidthMinFaceFrac {
    final parsed = parsedWidthMinFaceFrac;
    if (parsed == null) return 0.7;
    return parsed.clamp(fracMin, fracMax);
  }

  double get resolvedHeightSpanFrac {
    final parsed = parsedHeightSpanFrac;
    if (parsed == null) return 0.75;
    return parsed.clamp(fracMin, fracMax);
  }

  double get resolvedPivotU {
    final parsed = parsedPivotU;
    if (parsed == null) return 0.5;
    return parsed.clamp(pivotMin, pivotMax);
  }

  double get resolvedPivotV {
    final parsed = parsedPivotV;
    if (parsed == null) return 0.5;
    return parsed.clamp(pivotMin, pivotMax);
  }

  bool get isEmpty => toMap().isEmpty;

  bool get hasInvalidNumbers =>
      _hasInvalidInt(leftLandmark) ||
      _hasInvalidInt(rightLandmark) ||
      _hasInvalidInt(anchorLandmark) ||
      _hasInvalidDouble(widthScreenMult) ||
      _hasInvalidDouble(widthFaceFrac) ||
      _hasInvalidDouble(widthMinFaceFrac) ||
      _hasInvalidDouble(heightSpanFrac) ||
      _hasInvalidDouble(pivotU) ||
      _hasInvalidDouble(pivotV);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    final x = pinX?.trim();
    final y = pinY?.trim();
    if (x != null && x.isNotEmpty) map['pinX'] = x;
    if (y != null && y.isNotEmpty) map['pinY'] = y;

    final left = parsedLeftLandmark;
    if (left != null) map['leftLandmark'] = left;
    final right = parsedRightLandmark;
    if (right != null) map['rightLandmark'] = right;
    final anchor = parsedAnchorLandmark;
    if (anchor != null) map['anchorLandmark'] = anchor;

    final screenMult = parsedWidthScreenMult;
    if (screenMult != null) map['widthScreenMult'] = screenMult;
    if (widthFaceFrac != null && widthFaceFrac!.trim().isNotEmpty) {
      final faceFrac = parsedWidthFaceFrac;
      if (faceFrac != null) map['widthFaceFrac'] = faceFrac;
    }
    if (widthMinFaceFrac != null && widthMinFaceFrac!.trim().isNotEmpty) {
      final minFaceFrac = parsedWidthMinFaceFrac;
      if (minFaceFrac != null) map['widthMinFaceFrac'] = minFaceFrac;
    }
    if (heightSpanFrac != null && heightSpanFrac!.trim().isNotEmpty) {
      final heightFrac = parsedHeightSpanFrac;
      if (heightFrac != null) map['heightSpanFrac'] = heightFrac;
    }
    if (pivotU != null && pivotU!.trim().isNotEmpty) {
      map['pivotU'] = resolvedPivotU;
    }
    if (pivotV != null && pivotV!.trim().isNotEmpty) {
      map['pivotV'] = resolvedPivotV;
    }
    if (useAveragedEyes != null) map['useAveragedEyes'] = useAveragedEyes!;
    if (scaleFromFaceBox != null) map['scaleFromFaceBox'] = scaleFromFaceBox!;

    for (final entry in extras.entries) {
      map.putIfAbsent(entry.key, () => entry.value);
    }
    return map;
  }

  EffectAnchorFormData copyWith({
    String? pinX,
    String? pinY,
    String? leftLandmark,
    String? rightLandmark,
    String? anchorLandmark,
    String? widthScreenMult,
    String? widthFaceFrac,
    String? widthMinFaceFrac,
    String? heightSpanFrac,
    String? pivotU,
    String? pivotV,
    bool? useAveragedEyes,
    bool? scaleFromFaceBox,
    Map<String, dynamic>? extras,
    bool clearPinX = false,
    bool clearPinY = false,
    bool clearLeftLandmark = false,
    bool clearRightLandmark = false,
    bool clearAnchorLandmark = false,
    bool clearWidthScreenMult = false,
    bool clearWidthFaceFrac = false,
    bool clearWidthMinFaceFrac = false,
    bool clearHeightSpanFrac = false,
    bool clearPivotU = false,
    bool clearPivotV = false,
    bool clearUseAveragedEyes = false,
    bool clearScaleFromFaceBox = false,
  }) {
    return EffectAnchorFormData(
      pinX: clearPinX ? null : (pinX ?? this.pinX),
      pinY: clearPinY ? null : (pinY ?? this.pinY),
      leftLandmark: clearLeftLandmark
          ? null
          : (leftLandmark ?? this.leftLandmark),
      rightLandmark: clearRightLandmark
          ? null
          : (rightLandmark ?? this.rightLandmark),
      anchorLandmark: clearAnchorLandmark
          ? null
          : (anchorLandmark ?? this.anchorLandmark),
      widthScreenMult: clearWidthScreenMult
          ? null
          : (widthScreenMult ?? this.widthScreenMult),
      widthFaceFrac: clearWidthFaceFrac
          ? null
          : (widthFaceFrac ?? this.widthFaceFrac),
      widthMinFaceFrac: clearWidthMinFaceFrac
          ? null
          : (widthMinFaceFrac ?? this.widthMinFaceFrac),
      heightSpanFrac: clearHeightSpanFrac
          ? null
          : (heightSpanFrac ?? this.heightSpanFrac),
      pivotU: clearPivotU ? null : (pivotU ?? this.pivotU),
      pivotV: clearPivotV ? null : (pivotV ?? this.pivotV),
      useAveragedEyes: clearUseAveragedEyes
          ? null
          : (useAveragedEyes ?? this.useAveragedEyes),
      scaleFromFaceBox: clearScaleFromFaceBox
          ? null
          : (scaleFromFaceBox ?? this.scaleFromFaceBox),
      extras: extras ?? this.extras,
    );
  }

  static int? _parseInt(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text);
  }

  static double? _parseDouble(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return double.tryParse(text);
  }

  static bool _hasInvalidInt(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return false;
    return int.tryParse(text) == null;
  }

  static bool _hasInvalidDouble(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return false;
    return double.tryParse(text) == null;
  }

  @override
  List<Object?> get props => [
    pinX,
    pinY,
    leftLandmark,
    rightLandmark,
    anchorLandmark,
    widthScreenMult,
    widthFaceFrac,
    widthMinFaceFrac,
    heightSpanFrac,
    pivotU,
    pivotV,
    useAveragedEyes,
    scaleFromFaceBox,
    extras,
  ];
}

class EffectAnchorPinOption {
  const EffectAnchorPinOption({
    required this.value,
    required this.labelKey,
    required this.fallbackLabel,
    this.descriptionKey,
    this.fallbackDescription,
  });

  final String value;
  final String labelKey;
  final String fallbackLabel;
  final String? descriptionKey;
  final String? fallbackDescription;
}

class EffectAnchorLandmarkOption {
  const EffectAnchorLandmarkOption({
    required this.index,
    required this.labelKey,
    required this.fallbackLabel,
  });

  final int index;
  final String labelKey;
  final String fallbackLabel;
}

/// Common anchor pin values from the Camera Studio seed pack.
abstract final class EffectAnchorPinOptions {
  static const pinX = <EffectAnchorPinOption>[
    EffectAnchorPinOption(
      value: 'nose_bridge',
      labelKey: 'fePinNoseBridge',
      fallbackLabel: 'Nose bridge',
      descriptionKey: 'fePinNoseBridgeDesc',
      fallbackDescription: 'Centers horizontally on the nose bridge.',
    ),
    EffectAnchorPinOption(
      value: 'eye_center',
      labelKey: 'fePinEyeCenter',
      fallbackLabel: 'Eye center',
      descriptionKey: 'fePinEyeCenterDesc',
      fallbackDescription: 'Centers horizontally between the eyes.',
    ),
    EffectAnchorPinOption(
      value: 'eye_midpoint',
      labelKey: 'fePinEyeMidpoint',
      fallbackLabel: 'Eye midpoint',
      descriptionKey: 'fePinEyeMidpointDesc',
      fallbackDescription: 'Centers horizontally between the outer eye corners.',
    ),
    EffectAnchorPinOption(
      value: 'mouth_midpoint',
      labelKey: 'fePinMouthMidpoint',
      fallbackLabel: 'Mouth midpoint',
      descriptionKey: 'fePinMouthMidpointDesc',
      fallbackDescription: 'Centers horizontally on the mouth.',
    ),
    EffectAnchorPinOption(
      value: 'face_center',
      labelKey: 'fePinFaceCenter',
      fallbackLabel: 'Face center',
      descriptionKey: 'fePinFaceCenterDesc',
      fallbackDescription: 'Centers horizontally on the face.',
    ),
  ];

  static const pinY = <EffectAnchorPinOption>[
    EffectAnchorPinOption(
      value: 'eye_line',
      labelKey: 'fePinEyeLine',
      fallbackLabel: 'Eye line',
      descriptionKey: 'fePinEyeLineDesc',
      fallbackDescription: 'Aligns vertically with the eye line.',
    ),
    EffectAnchorPinOption(
      value: 'nose_tip',
      labelKey: 'fePinNoseTip',
      fallbackLabel: 'Nose tip',
      descriptionKey: 'fePinNoseTipDesc',
      fallbackDescription: 'Aligns vertically with the nose tip.',
    ),
    EffectAnchorPinOption(
      value: 'chin',
      labelKey: 'fePinChin',
      fallbackLabel: 'Chin',
      descriptionKey: 'fePinChinDesc',
      fallbackDescription: 'Aligns vertically with the chin.',
    ),
    EffectAnchorPinOption(
      value: 'anchor',
      labelKey: 'fePinAnchor',
      fallbackLabel: 'Anchor landmark',
      descriptionKey: 'fePinAnchorDesc',
      fallbackDescription: 'Aligns vertically with the anchor landmark.',
    ),
    EffectAnchorPinOption(
      value: 'top_head_offset',
      labelKey: 'fePinTopHeadOffset',
      fallbackLabel: 'Top head offset',
      descriptionKey: 'fePinTopHeadOffsetDesc',
      fallbackDescription: 'Aligns vertically above the forehead.',
    ),
    EffectAnchorPinOption(
      value: 'mouth_midpoint',
      labelKey: 'fePinMouthMidpoint',
      fallbackLabel: 'Mouth midpoint',
      descriptionKey: 'fePinMouthMidpointDesc',
      fallbackDescription: 'Aligns vertically with the mouth.',
    ),
  ];

  static EffectAnchorPinOption? findPinX(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final option in pinX) {
      if (option.value == normalized) return option;
    }
    return null;
  }

  static EffectAnchorPinOption? findPinY(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final option in pinY) {
      if (option.value == normalized) return option;
    }
    return null;
  }
}

/// MediaPipe face mesh indices used by the Camera Studio seed pack.
abstract final class EffectAnchorLandmarkOptions {
  static const all = <EffectAnchorLandmarkOption>[
    EffectAnchorLandmarkOption(
      index: 33,
      labelKey: 'feLandmarkLeftEyeOuter',
      fallbackLabel: 'Left eye (outer)',
    ),
    EffectAnchorLandmarkOption(
      index: 133,
      labelKey: 'feLandmarkLeftEyeInner',
      fallbackLabel: 'Left eye (inner)',
    ),
    EffectAnchorLandmarkOption(
      index: 263,
      labelKey: 'feLandmarkRightEyeOuter',
      fallbackLabel: 'Right eye (outer)',
    ),
    EffectAnchorLandmarkOption(
      index: 362,
      labelKey: 'feLandmarkRightEyeInner',
      fallbackLabel: 'Right eye (inner)',
    ),
    EffectAnchorLandmarkOption(
      index: 168,
      labelKey: 'feLandmarkNoseBridge',
      fallbackLabel: 'Nose bridge',
    ),
    EffectAnchorLandmarkOption(
      index: 1,
      labelKey: 'feLandmarkNoseTip',
      fallbackLabel: 'Nose tip',
    ),
    EffectAnchorLandmarkOption(
      index: 10,
      labelKey: 'feLandmarkForehead',
      fallbackLabel: 'Forehead center',
    ),
    EffectAnchorLandmarkOption(
      index: 152,
      labelKey: 'feLandmarkChin',
      fallbackLabel: 'Chin',
    ),
    EffectAnchorLandmarkOption(
      index: 61,
      labelKey: 'feLandmarkLeftMouth',
      fallbackLabel: 'Left mouth corner',
    ),
    EffectAnchorLandmarkOption(
      index: 291,
      labelKey: 'feLandmarkRightMouth',
      fallbackLabel: 'Right mouth corner',
    ),
    EffectAnchorLandmarkOption(
      index: 17,
      labelKey: 'feLandmarkMouthCenter',
      fallbackLabel: 'Mouth center',
    ),
  ];

  static const leftSuggestions = <int>[33, 133, 61];
  static const rightSuggestions = <int>[263, 362, 291];
  static const anchorSuggestions = <int>[168, 1, 10, 17];

  static EffectAnchorLandmarkOption? find(int? index) {
    if (index == null) return null;
    for (final option in all) {
      if (option.index == index) return option;
    }
    return null;
  }

  static List<EffectAnchorLandmarkOption> optionsForField({
    required List<int> suggestions,
    int? selected,
  }) {
    final ordered = <EffectAnchorLandmarkOption>[];
    final seen = <int>{};

    void addOption(EffectAnchorLandmarkOption option) {
      if (seen.add(option.index)) ordered.add(option);
    }

    for (final index in suggestions) {
      final option = find(index);
      if (option != null) addOption(option);
    }

    final selectedOption = find(selected);
    if (selectedOption != null) addOption(selectedOption);

    for (final option in all) {
      addOption(option);
    }

    return ordered;
  }

  static String labelForIndex(int index, String Function(String, String) tOr) {
    final option = find(index);
    if (option == null) {
      return tOr(
        'feLandmarkCustomIndex',
        'Point {index}',
      ).replaceAll('{index}', '$index');
    }
    return '${option.index} — ${tOr(option.labelKey, option.fallbackLabel)}';
  }
}
