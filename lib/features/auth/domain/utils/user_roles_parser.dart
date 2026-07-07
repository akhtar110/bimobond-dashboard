import '../../../users/domain/entities/user_entity.dart';

List<UserRole> parseUserRoles(dynamic raw) {
  if (raw is List) {
    return raw.map((entry) => _mapRole(entry.toString())).toList();
  }
  if (raw is Map) {
    return raw.entries
        .where((entry) => entry.value == true)
        .map((entry) => _mapRole(entry.key.toString()))
        .toList();
  }
  return const [];
}

UserRole _mapRole(String role) {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return UserRole.admin;
    case 'MODERATOR':
      return UserRole.moderator;
    default:
      return UserRole.user;
  }
}
