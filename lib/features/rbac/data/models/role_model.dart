import '../../domain/entities/role_entity.dart';
import 'permission_model.dart';

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.slug,
    required super.name,
    super.description,
    required super.isSystem,
    required super.isActive,
    required super.userCount,
    required super.permissionCount,
    required super.permissions,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Handles both list summaries (permissions absent, `permissionCount`
  /// present) and detail payloads (`permissions` list plus `_count.users`).
  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    final countMap = count is Map
        ? Map<String, dynamic>.from(count)
        : const <String, dynamic>{};

    final rawPermissions = json['permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions
              .map(_permissionFromValue)
              .whereType<PermissionModel>()
              .toList(growable: false)
        : const <PermissionModel>[];

    final slug = readJsonString(json, ['slug']);
    return RoleModel(
      id: readJsonString(json, ['id', '_id']),
      slug: slug,
      name: readJsonString(json, ['name'], fallback: slug),
      description: readJsonNullableString(json, ['description']),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      userCount: _readInt([json['userCount'], countMap['users']]),
      permissionCount: _readInt([
        json['permissionCount'],
        countMap['permissions'],
        rawPermissions is List ? permissions.length : null,
      ]),
      permissions: permissions,
      createdAt: readJsonDate(json['createdAt']),
      updatedAt: readJsonDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    if (description != null) 'description': description,
    'isSystem': isSystem,
    'isActive': isActive,
    'userCount': userCount,
    'permissionCount': permissionCount,
    'permissions': permissions.map((permission) => permission.key).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

PermissionModel? _permissionFromValue(Object? value) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    // Detail payloads may nest as { permission: {...} } (join-table rows).
    final nested = map['permission'];
    if (nested is Map) {
      return PermissionModel.fromJson(Map<String, dynamic>.from(nested));
    }
    return PermissionModel.fromJson(map);
  }
  if (value is String && value.isNotEmpty) {
    return PermissionModel.fromKey(value);
  }
  return null;
}

int _readInt(List<Object?> candidates) {
  for (final candidate in candidates) {
    if (candidate is int) return candidate;
    final parsed = int.tryParse(candidate?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}
