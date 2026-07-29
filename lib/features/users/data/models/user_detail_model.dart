import '../../domain/entities/user_detail_entity.dart';
import '../../domain/entities/user_post_entity.dart';
import '../../domain/entities/user_wallet_entity.dart';
import 'user_model.dart';

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
    final countsRaw = json['_count'] is Map
        ? Map<String, dynamic>.from(json['_count'] as Map)
        : null;
    final counts = UserRelationCountsEntity.tryParse(countsRaw);
    final wallet = UserWalletEntity.tryParse(json['wallet']);
    return UserDetailModel(
      user: UserModel.fromJson(json, counts: countsRaw),
      posts: posts,
      wallet: wallet,
      devices: (json['devices'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      counts: counts,
    );
  }
}
