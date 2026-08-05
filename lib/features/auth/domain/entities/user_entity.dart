import '../../../users/domain/entities/user_entity.dart';

class DashboardUserEntity {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final bool isVerified;
  final bool isNewUser;
  final bool isProfileIncomplete;
  final List<UserRole> roles;

  DashboardUserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.isVerified,
    required this.isNewUser,
    required this.isProfileIncomplete,
    this.roles = const [],
  });

  /// Prefer full name when available; otherwise username.
  String get displayFullName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return username.trim();
  }
}