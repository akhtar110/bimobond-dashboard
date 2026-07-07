import '../../../users/domain/entities/user_entity.dart';

class DashboardUserEntity {
  final String id;
  final String email;
  final String username;
  final bool isVerified;
  final bool isNewUser;
  final bool isProfileIncomplete;
  final List<UserRole> roles;

  DashboardUserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.isVerified,
    required this.isNewUser,
    required this.isProfileIncomplete,
    this.roles = const [],
  });
}