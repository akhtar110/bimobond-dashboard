/// Wallet summary returned on admin user list/detail payloads.
class UserWalletEntity {
  const UserWalletEntity({
    this.id,
    this.userId,
    this.kind,
    required this.balanceCoins,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String? kind;
  final double balanceCoins;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static UserWalletEntity? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final balance = json['balanceCoins'] ?? json['balance'];
    double coins = 0;
    if (balance is num) {
      coins = balance.toDouble();
    } else if (balance is String) {
      coins = double.tryParse(balance) ?? 0;
    }
    return UserWalletEntity(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      kind: json['kind']?.toString(),
      balanceCoins: coins,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

/// Relation `_count` block from admin user payloads.
class UserRelationCountsEntity {
  const UserRelationCountsEntity({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.reportsRecv = 0,
    this.sentGifts = 0,
    this.receivedGifts = 0,
    this.wonAuctions = 0,
  });

  final int posts;
  final int followers;
  final int following;
  final int reportsRecv;
  final int sentGifts;
  final int receivedGifts;
  final int wonAuctions;

  static UserRelationCountsEntity? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    int read(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    return UserRelationCountsEntity(
      posts: read(json['posts'] ?? json['post']),
      followers: read(json['followers'] ?? json['follower']),
      following: read(json['following'] ?? json['followings']),
      reportsRecv: read(json['reportsRecv']),
      sentGifts: read(json['sentGifts']),
      receivedGifts: read(json['receivedGifts']),
      wonAuctions: read(json['wonAuctions']),
    );
  }
}
