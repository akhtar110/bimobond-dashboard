import 'package:equatable/equatable.dart';

import 'role_entity.dart';

/// Lightweight user summary for role-holder lists.
class RoleUserEntity extends Equatable {
  const RoleUserEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isBanned = false,
    this.isVerified = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isBanned;
  final bool isVerified;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return username;
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isBanned, isVerified];
}

/// Well-known system roles surfaced on the RBAC overview.
enum SystemRoleKind {
  admin,
  member,
  moderator,
  superAdmin,
}

extension SystemRoleKindX on SystemRoleKind {
  String get localizationKey => switch (this) {
        SystemRoleKind.admin => 'roleAdmin',
        SystemRoleKind.member => 'roleMember',
        SystemRoleKind.moderator => 'roleModerator',
        SystemRoleKind.superAdmin => 'roleSuperAdmin',
      };

  String get fallbackLabel => switch (this) {
        SystemRoleKind.admin => 'Admin',
        SystemRoleKind.member => 'Member',
        SystemRoleKind.moderator => 'Moderator',
        SystemRoleKind.superAdmin => 'Super admin',
      };

  String get fallbackDescription => switch (this) {
        SystemRoleKind.admin => 'Platform administrators',
        SystemRoleKind.member => 'Standard members',
        SystemRoleKind.moderator => 'Content moderators',
        SystemRoleKind.superAdmin => 'Highest privilege operators',
      };

  /// Slug matchers against RBAC role slugs from the API.
  bool matchesSlug(String slug) {
    final s = slug.trim().toLowerCase().replaceAll('-', '_');
    return switch (this) {
      SystemRoleKind.superAdmin =>
        s == 'super_admin' ||
            s == 'superadmin' ||
            s.contains('super_admin') ||
            s.contains('superadmin'),
      SystemRoleKind.admin =>
        (s == 'admin' || s.endsWith('_admin') || s.startsWith('admin')) &&
            !s.contains('super'),
      SystemRoleKind.moderator =>
        s == 'moderator' || s == 'mod' || s.contains('moderator'),
      SystemRoleKind.member =>
        s == 'member' || s == 'user' || s == 'member_user' || s == 'default',
    };
  }
}

RoleEntity? findRoleForKind(List<RoleEntity> roles, SystemRoleKind kind) {
  for (final role in roles) {
    if (kind.matchesSlug(role.slug)) return role;
  }
  // Prefer system roles when multiple soft-match (already handled by order).
  return null;
}
