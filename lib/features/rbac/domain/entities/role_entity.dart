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

  RoleEntity copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,
    bool? isSystem,
    bool? isActive,
    int? userCount,
    int? permissionCount,
    List<PermissionEntity>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
  }) {
    return RoleEntity(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      userCount: userCount ?? this.userCount,
      permissionCount: permissionCount ?? this.permissionCount,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
