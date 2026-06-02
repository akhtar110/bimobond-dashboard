import 'user_entity.dart';
import 'user_post_entity.dart';

class UserDetailEntity {
  final UserEntity user;
  final List<UserPostEntity> posts;
  final Map<String, dynamic>? wallet;
  final List<Map<String, dynamic>>? devices;
  final Map<String, dynamic>? counts;

  const UserDetailEntity({
    required this.user,
    required this.posts,
    this.wallet,
    this.devices,
    this.counts,
  });

  UserDetailEntity copyWith({
    UserEntity? user,
    List<UserPostEntity>? posts,
    Map<String, dynamic>? wallet,
    List<Map<String, dynamic>>? devices,
    Map<String, dynamic>? counts,
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
