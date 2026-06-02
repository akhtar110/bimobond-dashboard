import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';

import '../../domain/entities/user_detail_entity.dart';
import 'user_model.dart';
import '../../domain/entities/user_post_entity.dart';

class UserDetailModel extends UserDetailEntity {
  UserDetailModel({
    required super.user,
    required super.posts,
    super.wallet,
    super.devices,
    super.counts,
  });

  factory UserDetailModel.fromJson(
    Map<String, dynamic> json, [
    List<UserPostEntity> posts = const [],
  ]) {
    return UserDetailModel(
      user: UserModel.fromJson(json),
      posts: posts,
      wallet: json['wallet'] as Map<String, dynamic>?,
      devices: (json['devices'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      counts: json['_count'] as Map<String, dynamic>?,
    );
  }
}
