import '../../domain/entities/user_entity.dart';

class DashboardUserModel extends DashboardUserEntity {
  DashboardUserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.isVerified,
    required super.isNewUser,
    required super.isProfileIncomplete,
  });

  factory DashboardUserModel.fromJson(Map<String, dynamic> json) {
    return DashboardUserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isNewUser: json['isNewUser'] ?? false,
      isProfileIncomplete: json['isProfileIncomplete'] ?? false,
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
    };
  }
}
