import '../../domain/entities/permission_entity.dart';

class PermissionModel extends PermissionEntity {
  const PermissionModel({
    required super.id,
    required super.key,
    required super.group,
    required super.label,
    super.description,
    required super.action,
    required super.createdAt,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    final key = readJsonString(json, ['key', 'code', 'slug']);
    return PermissionModel(
      id: readJsonString(json, ['id', '_id'], fallback: key),
      key: key,
      group: readJsonString(json, [
        'group',
        'resource',
        'module',
      ], fallback: 'General'),
      label: readJsonString(json, [
        'label',
        'name',
        'displayName',
      ], fallback: key),
      description: readJsonNullableString(json, ['description']),
      action: readJsonString(json, ['action']),
      createdAt: readJsonDate(json['createdAt']),
    );
  }

  /// Builds a placeholder for APIs that return permissions as plain keys.
  factory PermissionModel.fromKey(String key) => PermissionModel(
    id: key,
    key: key,
    group: 'General',
    label: key,
    action: '',
    createdAt: unknownJsonDate,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'group': group,
    'label': label,
    if (description != null) 'description': description,
    'action': action,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Sentinel used when the backend omits a date the contract requires.
final DateTime unknownJsonDate = DateTime.fromMillisecondsSinceEpoch(0);

String readJsonString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

String? readJsonNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = readJsonString(json, keys);
  return value.isEmpty ? null : value;
}

DateTime readJsonDate(Object? value) {
  if (value == null) return unknownJsonDate;
  return DateTime.tryParse(value.toString()) ?? unknownJsonDate;
}
