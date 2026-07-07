import '../../domain/entities/user_follow_entity.dart';

class UserFollowSummaryModel extends UserFollowSummaryEntity {
  const UserFollowSummaryModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    required super.isVerified,
  });

  factory UserFollowSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserFollowSummaryModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class UserFollowListPageModel extends UserFollowListPageEntity {
  const UserFollowListPageModel({
    required super.users,
    required super.total,
    required super.page,
    required super.lastPage,
  });

  factory UserFollowListPageModel.fromJson(
    Map<String, dynamic> json,
    UserFollowListKind kind,
  ) {
    final listKey = kind == UserFollowListKind.followers ? 'followers' : 'following';
    final rawList = json[listKey];
    final users = rawList is List
        ? rawList
            .whereType<Map>()
            .map((e) => UserFollowSummaryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <UserFollowSummaryModel>[];

    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    return UserFollowListPageModel(
      users: users,
      total: _int(meta['total']) ?? users.length,
      page: _int(meta['page']) ?? 1,
      lastPage: _int(meta['lastPage']) ?? 1,
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
