import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/utils/user_roles_parser.dart';

class DashboardUserModel extends DashboardUserEntity {
  DashboardUserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.isVerified,
    required super.isNewUser,
    required super.isProfileIncomplete,
    super.roles = const [],
  });

  static String _roleApiValue(UserRole role) => switch (role) {
        UserRole.superAdmin => 'SUPER_ADMIN',
        UserRole.admin => 'ADMIN',
        UserRole.moderator => 'MODERATOR',
        UserRole.user => 'USER',
      };

  factory DashboardUserModel.fromJson(Map<String, dynamic> json) {
    return DashboardUserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isNewUser: json['isNewUser'] ?? false,
      isProfileIncomplete: json['isProfileIncomplete'] ?? false,
      roles: parseUserRoles(json['roles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'isVerified': isVerified,
      'isNewUser': isNewUser,
      'isProfileIncomplete': isProfileIncomplete,
      'roles': roles.map(_roleApiValue).toList(),
    };
  }
}
