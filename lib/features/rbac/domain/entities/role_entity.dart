import 'package:equatable/equatable.dart';

import 'permission_entity.dart';

class RoleEntity extends Equatable {
  const RoleEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.isSystem,
    required this.isActive,
    required this.userCount,
    required this.permissionCount,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final int userCount;
  final int permissionCount;
  final List<PermissionEntity> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    description,
    isSystem,
    isActive,
    userCount,
    permissionCount,
    permissions,
    createdAt,
    updatedAt,
  ];
}
