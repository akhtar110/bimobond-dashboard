import 'package:equatable/equatable.dart';

import 'role_entity.dart';

class UserAuthContextEntity extends Equatable {
  const UserAuthContextEntity({
    required this.permissions,
    required this.roleSlugs,
    required this.legacyRoles,
    required this.roles,
  });

  final List<String> permissions;
  final List<String> roleSlugs;
  final List<String> legacyRoles;
  final List<RoleEntity> roles;

  Set<String> get permissionKeys => permissions.toSet();

  @override
  List<Object?> get props => [permissions, roleSlugs, legacyRoles, roles];
}
