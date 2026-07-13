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

/// Strongly typed filter slider values keyed by schema setting key.
class FilterSettingsEntity extends Equatable {
  const FilterSettingsEntity(this.values);

  final Map<String, int> values;

  static const empty = FilterSettingsEntity({});

  int valueFor(FilterSettingDefinitionEntity definition) =>
      values[definition.key] ?? definition.defaultValue;

  FilterSettingsEntity withValue(String key, int value) {
    final next = Map<String, int>.from(values);
    next[key] = value;
    return FilterSettingsEntity(next);
  }

  FilterSettingsEntity mergeFromMap(Map<String, int> incoming) {
    if (incoming.isEmpty) return this;
    final next = Map<String, int>.from(values);
    next.addAll(incoming);
    return FilterSettingsEntity(next);
  }

  FilterSettingsEntity resetToDefaults(FilterSettingsSchemaEntity schema) =>
      FilterSettingsEntity(schema.defaultValues());

  /// Create payload: only non-default values.
  Map<String, dynamic> toApiJson(FilterSettingsSchemaEntity schema) {
    final json = <String, dynamic>{};
    for (final definition in schema.settings) {
      final value = valueFor(definition);
      if (value != definition.defaultValue) {
        json[definition.key] = value;
      }
    }
    return json;
  }

  /// Update payload: every key that changed vs [previous], including resets to
  /// default (so merged PATCH does not leave stale beauty values).
  Map<String, dynamic> toUpdateApiJson(
    FilterSettingsSchemaEntity schema, {
    required FilterSettingsEntity previous,
  }) {
    final json = <String, dynamic>{};
    for (final definition in schema.settings) {
      final value = valueFor(definition);
      final prev = previous.valueFor(definition);
      if (value != prev) {
        json[definition.key] = value;
      }
    }
    return json;
  }

  /// Full snapshot of all schema keys (replace-style writes).
  Map<String, dynamic> toFullApiJson(FilterSettingsSchemaEntity schema) {
    return {
      for (final definition in schema.settings)
        definition.key: valueFor(definition),
    };
  }

  bool equalsDefaults(FilterSettingsSchemaEntity schema) {
    for (final definition in schema.settings) {
      if (valueFor(definition) != definition.defaultValue) return false;
    }
    return true;
  }

  List<({FilterSettingDefinitionEntity definition, int value})> nonDefaultEntries(
    FilterSettingsSchemaEntity schema,
  ) {
    final entries = <({FilterSettingDefinitionEntity definition, int value})>[];
    for (final definition in schema.settings) {
      final value = valueFor(definition);
      if (value != definition.defaultValue) {
        entries.add((definition: definition, value: value));
      }
    }
    return entries;
  }

  @override
  List<Object?> get props => [values];
}
