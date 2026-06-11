import '../../../../core/utils/api_page_parser.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../user_activity/data/models/user_gift_transaction_model.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../../user_activity/domain/entities/user_gift_transaction_entity.dart';
import '../../../users/data/models/user_post_model.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/user_report_entities.dart';

abstract final class UserReportModels {
  UserReportModels._();

  static UserReportsOverviewEntity overviewFromJson(dynamic data) {
    final json = _unwrap(data);
    final totalsRaw = _section(json, 'totals');
    final topRaw = json['topUsers'];
    Map<String, dynamic> topMap = const {};
    if (topRaw is Map<String, dynamic>) {
      topMap = topRaw;
    }

    return UserReportsOverviewEntity(
      period: _parsePeriod(json),
      totals: UserReportOverviewTotals(
        totalUsers: _int(totalsRaw['totalUsers']),
        newUsersInPeriod: _int(
          totalsRaw['newUsersInPeriod'] ?? totalsRaw['newInPeriod'],
        ),
        verifiedUsers: _int(totalsRaw['verifiedUsers'] ?? totalsRaw['verified']),
        bannedUsers: _int(totalsRaw['bannedUsers'] ?? totalsRaw['banned']),
        activeUsersInPeriod: _int(totalsRaw['activeUsersInPeriod']),
        postsInPeriod: _int(totalsRaw['postsInPeriod']),
        giftTransactionsInPeriod: _int(
          totalsRaw['giftTransactionsInPeriod'],
        ),
      ),
      topUsers: UserReportTopUsers(
        byFollowers: _parseTopUsers(topMap['byFollowers']),
        byPosts: _parseTopUsers(topMap['byPosts']),
        byLikes: _parseTopUsers(topMap['byLikes']),
      ),
    );
  }

  static PaginatedPage<UserReportListItemEntity> usersPageFromJson(
    dynamic data,
  ) {
    final json = _unwrap(data);
    final rows = ApiPageParser.extractList(json);
    final meta = ApiPageParser.extractMeta(json);
    final items = rows.map(UserReportListItemModel.fromJson).toList();
    final page = ApiPageParser.intMeta(meta, 'page', fallback: 1);
    final lastPage = ApiPageParser.intMeta(
      meta,
      'totalPages',
      fallback: ApiPageParser.intMeta(meta, 'lastPage', fallback: 1),
    );
    return PaginatedPage(
      items: items,
      page: page,
      lastPage: lastPage,
      total: ApiPageParser.intMeta(meta, 'total', fallback: items.length),
    );
  }

  static UserReportDetailEntity detailFromJson(dynamic data) {
    final json = _unwrap(data);
    final profileRaw = _section(json, 'profile');
    final countsRaw = _section(json, 'counts');
    final walletRaw = _section(json, 'wallet');
    final devicesRaw = _section(json, 'devices');
    final periodActivityRaw = _section(json, 'periodActivity');
    final allTimeRaw = _section(json, 'allTimePostMetrics');
    final notificationsRaw = _section(json, 'notifications');

    return UserReportDetailEntity(
      period: _parsePeriod(json),
      profile: UserReportProfileModel.fromJson(profileRaw),
      counts: UserReportCountsModel.fromJson(countsRaw),
      wallet: UserReportWalletModel.fromJson(walletRaw),
      devices: UserReportDevicesSectionModel.fromJson(devicesRaw),
      periodActivity: UserReportPeriodActivityModel.fromJson(periodActivityRaw),
      allTimePostMetrics: UserReportPostMetricsModel.fromJson(allTimeRaw),
      recentPosts: _parsePosts(json['recentPosts']),
      topPostsInPeriod: _parsePosts(json['topPostsInPeriod']),
      recentGiftsSent: _parseGifts(json['recentGiftsSent']),
      recentGiftsReceived: _parseGifts(json['recentGiftsReceived']),
      notifications: UserReportNotificationsModel.fromJson(notificationsRaw),
    );
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return const {};
  }

  static Map<String, dynamic> _section(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    return const {};
  }

  static UserReportPeriod _parsePeriod(Map<String, dynamic> json) {
    final period = json['period'];
    if (period is Map<String, dynamic>) {
      return UserReportPeriod(
        from: _date(period['from']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        to: _date(period['to']) ?? DateTime.now(),
      );
    }
    return UserReportPeriod(from: DateTime.now(), to: DateTime.now());
  }

  static List<UserReportListItemEntity> _parseTopUsers(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) {
          if (entry is! Map<String, dynamic>) return null;
          if (entry['user'] is Map<String, dynamic>) {
            return UserReportListItemModel.fromJson(
              entry['user'] as Map<String, dynamic>,
            );
          }
          return UserReportListItemModel.fromJson(entry);
        })
        .whereType<UserReportListItemEntity>()
        .toList();
  }

  static List<UserPostEntity> _parsePosts(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UserPostModel.fromJson)
        .toList();
  }

  static List<UserGiftTransactionEntity> _parseGifts(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UserGiftTransactionModel.fromJson)
        .toList();
  }

  static int _int(dynamic value, {int fallback = 0}) =>
      ApiPageParser.intVal(value, fallback: fallback);

  static double _double(dynamic value, {double fallback = 0}) =>
      ApiPageParser.doubleVal(value, fallback: fallback);

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _roles(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }
}

class UserReportCountsModel extends UserReportCountsEntity {
  const UserReportCountsModel({
    super.devices,
    super.posts,
    super.followers,
    super.following,
    super.postLikes,
    super.comments,
    super.reposts,
    super.sentGifts,
    super.receivedGifts,
    super.hostedAuctions,
    super.wonAuctions,
    super.reportsRecv,
    super.reportsMade,
    super.notifications,
    super.fiatPurchases,
  });

  factory UserReportCountsModel.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const {};
    return UserReportCountsModel(
      devices: UserReportModels._int(map['devices']),
      posts: UserReportModels._int(map['posts']),
      followers: UserReportModels._int(map['followers']),
      following: UserReportModels._int(map['following']),
      postLikes: UserReportModels._int(map['postLikes']),
      comments: UserReportModels._int(map['comments']),
      reposts: UserReportModels._int(map['reposts']),
      sentGifts: UserReportModels._int(map['sentGifts']),
      receivedGifts: UserReportModels._int(map['receivedGifts']),
      hostedAuctions: UserReportModels._int(map['hostedAuctions']),
      wonAuctions: UserReportModels._int(map['wonAuctions']),
      reportsRecv: UserReportModels._int(map['reportsRecv']),
      reportsMade: UserReportModels._int(map['reportsMade']),
      notifications: UserReportModels._int(map['notifications']),
      fiatPurchases: UserReportModels._int(map['fiatPurchases']),
    );
  }
}

class UserReportListItemModel extends UserReportListItemEntity {
  const UserReportListItemModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
    super.roles,
    super.followerCount,
    super.followingCount,
    super.postCount,
    super.totalLikes,
    super.country,
    super.city,
    super.createdAt,
    super.walletBalanceUsd,
    super.deviceCount,
    super.counts,
  });

  factory UserReportListItemModel.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['counts'];
    return UserReportListItemModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      avatarUrl: resolveMediaUrl(
        json['avatarUrl'] as String? ?? json['avatar'] as String?,
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      roles: UserReportModels._roles(json['roles']),
      followerCount: UserReportModels._int(json['followerCount']),
      followingCount: UserReportModels._int(json['followingCount']),
      postCount: UserReportModels._int(json['postCount']),
      totalLikes: UserReportModels._int(json['totalLikes']),
      country: json['country'] as String?,
      city: json['city'] as String?,
      createdAt: UserReportModels._date(json['createdAt']),
      walletBalanceUsd: UserReportModels._double(json['walletBalanceUsd']),
      deviceCount: UserReportModels._int(
        json['deviceCount'] ?? (countsRaw is Map ? countsRaw['devices'] : null),
      ),
      counts: countsRaw is Map<String, dynamic>
          ? UserReportCountsModel.fromJson(countsRaw)
          : const UserReportCountsModel(),
    );
  }
}

class UserReportProfileModel extends UserReportProfileEntity {
  const UserReportProfileModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.bio,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
    super.banReason,
    super.bannedUntil,
    super.roles,
    super.followerCount,
    super.followingCount,
    super.postCount,
    super.totalLikes,
    super.country,
    super.city,
    super.language,
    super.createdAt,
    super.updatedAt,
  });

  factory UserReportProfileModel.fromJson(Map<String, dynamic> json) {
    return UserReportProfileModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: resolveMediaUrl(
        json['avatarUrl'] as String? ?? json['avatar'] as String?,
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      banReason: json['banReason'] as String?,
      bannedUntil: UserReportModels._date(json['bannedUntil']),
      roles: UserReportModels._roles(json['roles']),
      followerCount: UserReportModels._int(json['followerCount']),
      followingCount: UserReportModels._int(json['followingCount']),
      postCount: UserReportModels._int(json['postCount']),
      totalLikes: UserReportModels._int(json['totalLikes']),
      country: json['country'] as String?,
      city: json['city'] as String?,
      language: json['language'] as String?,
      createdAt: UserReportModels._date(json['createdAt']),
      updatedAt: UserReportModels._date(json['updatedAt']),
    );
  }
}

class UserReportWalletTransactionModel extends UserReportWalletTransactionEntity {
  const UserReportWalletTransactionModel({
    required super.id,
    required super.type,
    required super.action,
    required super.amountUsd,
    required super.balanceAfter,
    super.reason,
    super.createdAt,
  });

  factory UserReportWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return UserReportWalletTransactionModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      amountUsd: UserReportModels._double(json['amountUsd']),
      balanceAfter: UserReportModels._double(json['balanceAfter']),
      reason: json['reason'] as String?,
      createdAt: UserReportModels._date(json['createdAt']),
    );
  }
}

class UserReportWalletModel extends UserReportWalletEntity {
  const UserReportWalletModel({
    required super.balanceUsd,
    super.recentTransactions,
  });

  factory UserReportWalletModel.fromJson(Map<String, dynamic> json) {
    final txRaw = json['recentTransactions'];
    final txs = txRaw is List
        ? txRaw
            .whereType<Map<String, dynamic>>()
            .map(UserReportWalletTransactionModel.fromJson)
            .toList()
        : const <UserReportWalletTransactionEntity>[];

    return UserReportWalletModel(
      balanceUsd: UserReportModels._double(
        json['balanceUsd'] ?? json['balance'],
      ),
      recentTransactions: txs,
    );
  }
}

class UserReportDeviceSummaryModel extends UserReportDeviceSummaryEntity {
  const UserReportDeviceSummaryModel({
    required super.id,
    required super.deviceType,
    super.osVersion,
    super.appVersion,
    super.lastActiveIp,
    super.lastActiveAt,
  });

  factory UserReportDeviceSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserReportDeviceSummaryModel(
      id: json['id']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      lastActiveIp: json['lastActiveIp'] as String?,
      lastActiveAt: UserReportModels._date(json['lastActiveAt']),
    );
  }
}

class UserReportDevicesSectionModel extends UserReportDevicesSectionEntity {
  const UserReportDevicesSectionModel({
    required super.total,
    super.recent,
  });

  factory UserReportDevicesSectionModel.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent'];
    final recent = recentRaw is List
        ? recentRaw
            .whereType<Map<String, dynamic>>()
            .map(UserReportDeviceSummaryModel.fromJson)
            .toList()
        : const <UserReportDeviceSummaryEntity>[];

    return UserReportDevicesSectionModel(
      total: UserReportModels._int(json['total'], fallback: recent.length),
      recent: recent,
    );
  }
}

class UserReportPeriodActivityModel extends UserReportPeriodActivityEntity {
  const UserReportPeriodActivityModel({
    super.postsCreated,
    super.commentsMade,
    super.likesGiven,
    super.repostsMade,
    super.viewsOnPosts,
    super.likesOnPosts,
    super.commentsOnPosts,
    super.newFollowers,
    super.giftsSent,
    super.giftsReceived,
    super.giftRevenueUsd,
    super.auctionsHosted,
    super.auctionsWon,
  });

  factory UserReportPeriodActivityModel.fromJson(Map<String, dynamic> json) {
    return UserReportPeriodActivityModel(
      postsCreated: UserReportModels._int(json['postsCreated']),
      commentsMade: UserReportModels._int(json['commentsMade']),
      likesGiven: UserReportModels._int(json['likesGiven']),
      repostsMade: UserReportModels._int(json['repostsMade']),
      viewsOnPosts: UserReportModels._int(json['viewsOnPosts']),
      likesOnPosts: UserReportModels._int(json['likesOnPosts']),
      commentsOnPosts: UserReportModels._int(json['commentsOnPosts']),
      newFollowers: UserReportModels._int(json['newFollowers']),
      giftsSent: UserReportModels._int(json['giftsSent']),
      giftsReceived: UserReportModels._int(
        json['giftsReceived'] ?? json['receivedGifts'],
      ),
      giftRevenueUsd: UserReportModels._double(json['giftRevenueUsd']),
      auctionsHosted: UserReportModels._int(json['auctionsHosted']),
      auctionsWon: UserReportModels._int(json['auctionsWon']),
    );
  }
}

class UserReportPostMetricsModel extends UserReportPostMetricsEntity {
  const UserReportPostMetricsModel({
    super.views,
    super.likes,
    super.comments,
    super.saves,
    super.reposts,
    super.shares,
  });

  factory UserReportPostMetricsModel.fromJson(Map<String, dynamic> json) {
    return UserReportPostMetricsModel(
      views: UserReportModels._int(json['views']),
      likes: UserReportModels._int(json['likes']),
      comments: UserReportModels._int(json['comments']),
      saves: UserReportModels._int(json['saves']),
      reposts: UserReportModels._int(json['reposts']),
      shares: UserReportModels._int(json['shares']),
    );
  }
}

class UserReportNotificationsModel extends UserReportNotificationsEntity {
  const UserReportNotificationsModel({super.unreadCount});

  factory UserReportNotificationsModel.fromJson(Map<String, dynamic> json) {
    return UserReportNotificationsModel(
      unreadCount: UserReportModels._int(json['unreadCount']),
    );
  }
}
