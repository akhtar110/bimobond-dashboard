import '../../domain/entities/role_user_entity.dart';

class RoleUserModel extends RoleUserEntity {
  const RoleUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.avatarUrl,
    super.isBanned,
    super.isVerified,
  });

  factory RoleUserModel.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ??
        json['userName']?.toString() ??
        json['name']?.toString() ??
        '';
    return RoleUserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      username: username.isNotEmpty ? username : 'user',
      fullName: json['fullName']?.toString() ?? json['displayName']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      isBanned: json['isBanned'] == true,
      isVerified: json['isVerified'] == true,
    );
  }
}
