import '../../domain/entities/filter_settings_entities.dart';

class FilterSettingsSchemaModel extends FilterSettingsSchemaEntity {
  const FilterSettingsSchemaModel({
    required super.version,
    required super.bipolarRange,
    required super.unipolarRange,
    required super.groups,
    required super.settings,
  });

  factory FilterSettingsSchemaModel.fromJson(Map<String, dynamic> json) {
    final valueRange = json['valueRange'] as Map<String, dynamic>? ?? {};
    final bipolar = valueRange['bipolar'] as Map<String, dynamic>? ?? {};
    final unipolar = valueRange['unipolar'] as Map<String, dynamic>? ?? {};

    return FilterSettingsSchemaModel(
      version: _int(json['version']),
      bipolarRange: FilterSettingValueRangeEntity(
        min: _int(bipolar['min'], fallback: -100),
        max: _int(bipolar['max'], fallback: 100),
        defaultValue: _int(bipolar['default'], fallback: 0),
      ),
      unipolarRange: FilterSettingValueRangeEntity(
        min: _int(unipolar['min']),
        max: _int(unipolar['max'], fallback: 100),
        defaultValue: _int(unipolar['default']),
      ),
      groups: (json['groups'] as List? ?? [])
          .map(
            (e) => FilterSettingGroupEntity(
              key: e['key']?.toString() ?? '',
              label: e['label']?.toString() ?? '',
              description: e['description']?.toString(),
            ),
          )
          .toList(),
      settings: (json['settings'] as List? ?? [])
          .map(
            (e) => FilterSettingDefinitionEntity(
              key: e['key']?.toString() ?? '',
              label: e['label']?.toString() ?? '',
              group: e['group']?.toString() ?? '',
              type: e['type']?.toString() ?? 'bipolar',
              min: _int(e['min']),
              max: _int(e['max'], fallback: 100),
              defaultValue: _int(e['default']),
              step: _int(e['step'], fallback: 1),
              colorMatrix: e['colorMatrix'] == true,
              clientOnly: e['clientOnly'] == true,
              description: e['description']?.toString(),
            ),
          )
          .toList(),
    );
  }
}

FilterSettingsEntity parseFilterSettings(dynamic raw) {
  if (raw is! Map) return FilterSettingsEntity.empty;
  return FilterSettingsEntity.fromJson(Map<String, dynamic>.from(raw));
}

List<double> parseColorMatrix(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0)
      .toList();
}

int _int(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
