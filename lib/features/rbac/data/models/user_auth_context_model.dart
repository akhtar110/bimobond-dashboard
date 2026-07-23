import '../../domain/entities/user_auth_context_entity.dart';
import 'role_model.dart';

class UserAuthContextModel extends UserAuthContextEntity {
  const UserAuthContextModel({
    required super.permissions,
    required super.roleSlugs,
    required super.legacyRoles,
    required super.roles,
  });

  factory UserAuthContextModel.fromJson(Map<String, dynamic> json) {
    final roles = _rawList(json['roles'])
        .whereType<Map>()
        .map((value) => RoleModel.fromJson(Map<String, dynamic>.from(value)))
        .toList(growable: false);

    final roleSlugs = _stringList(json['roleSlugs']);
    return UserAuthContextModel(
      permissions: _stringList(json['permissions']),
      roleSlugs: roleSlugs.isNotEmpty
          ? roleSlugs
          : roles.map((role) => role.slug).toList(growable: false),
      legacyRoles: _stringList(json['legacyRoles']),
      roles: roles,
    );
  }
}

List<Object?> _rawList(Object? value) => value is List ? value : const [];

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .where((item) => item is String || item is num)
      .map((item) => item.toString())
      .toList(growable: false);
}
