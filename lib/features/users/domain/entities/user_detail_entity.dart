import 'user_entity.dart';
import 'user_post_entity.dart';
import 'user_wallet_entity.dart';

class UserDetailEntity {
  final UserEntity user;
  final List<UserPostEntity> posts;
  final UserWalletEntity? wallet;
  final List<Map<String, dynamic>>? devices;
  final UserRelationCountsEntity? counts;

  const UserDetailEntity({
    required this.user,
    required this.posts,
    this.wallet,
    this.devices,
    this.counts,
  });

  /// Raw map view for widgets that still read `wallet['balanceCoins']`.
  Map<String, dynamic>? get walletMap {
    final w = wallet ?? user.wallet;
    if (w == null) return null;
    return {
      'id': w.id,
      'userId': w.userId,
      'kind': w.kind,
      'balanceCoins': w.balanceCoins,
      'createdAt': w.createdAt?.toIso8601String(),
      'updatedAt': w.updatedAt?.toIso8601String(),
    };
  }

  UserDetailEntity copyWith({
    UserEntity? user,
    List<UserPostEntity>? posts,
    UserWalletEntity? wallet,
    List<Map<String, dynamic>>? devices,
    UserRelationCountsEntity? counts,
  }) {
    return UserDetailEntity(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      wallet: wallet ?? this.wallet,
      devices: devices ?? this.devices,
      counts: counts ?? this.counts,
    );
  }
}
