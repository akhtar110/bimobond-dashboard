class DashboardUserEntity {
  final String id;
  final String email;
  final String username;
  final bool isVerified;
  final bool isNewUser;
  final bool isProfileIncomplete;

  DashboardUserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.isVerified,
    required this.isNewUser,
    required this.isProfileIncomplete,
  });
}