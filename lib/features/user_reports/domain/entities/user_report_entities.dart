import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/user_post_entity.dart';
import '../../../user_activity/domain/entities/user_gift_transaction_entity.dart';

class UserReportPeriod extends Equatable {
  const UserReportPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class UserReportOverviewTotals extends Equatable {
  const UserReportOverviewTotals({
    required this.totalUsers,
    required this.newUsersInPeriod,
    required this.verifiedUsers,
    required this.bannedUsers,
    required this.activeUsersInPeriod,
    required this.postsInPeriod,
    required this.giftTransactionsInPeriod,
  });

  final int totalUsers;
  final int newUsersInPeriod;
  final int verifiedUsers;
  final int bannedUsers;
  final int activeUsersInPeriod;
  final int postsInPeriod;
  final int giftTransactionsInPeriod;

  @override
  List<Object?> get props => [
        totalUsers,
        newUsersInPeriod,
        verifiedUsers,
        bannedUsers,
        activeUsersInPeriod,
        postsInPeriod,
        giftTransactionsInPeriod,
      ];
}

class UserReportTopUsers extends Equatable {
  const UserReportTopUsers({
    this.byFollowers = const [],
    this.byPosts = const [],
    this.byLikes = const [],
  });

  final List<UserReportListItemEntity> byFollowers;
  final List<UserReportListItemEntity> byPosts;
  final List<UserReportListItemEntity> byLikes;

  @override
  List<Object?> get props => [byFollowers, byPosts, byLikes];
}

class UserReportsOverviewEntity extends Equatable {
  const UserReportsOverviewEntity({
    required this.period,
    required this.totals,
    required this.topUsers,
  });

  final UserReportPeriod period;
  final UserReportOverviewTotals totals;
  final UserReportTopUsers topUsers;

  @override
  List<Object?> get props => [period, totals, topUsers];
}

class UserReportCountsEntity extends Equatable {
  const UserReportCountsEntity({
    this.devices = 0,
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.postLikes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.sentGifts = 0,
    this.receivedGifts = 0,
    this.hostedAuctions = 0,
    this.wonAuctions = 0,
    this.reportsRecv = 0,
    this.reportsMade = 0,
    this.notifications = 0,
    this.fiatPurchases = 0,
  });

  final int devices;
  final int posts;
  final int followers;
  final int following;
  final int postLikes;
  final int comments;
  final int reposts;
  final int sentGifts;
  final int receivedGifts;
  final int hostedAuctions;
  final int wonAuctions;
  final int reportsRecv;
  final int reportsMade;
  final int notifications;
  final int fiatPurchases;

  @override
  List<Object?> get props => [
        devices,
        posts,
        followers,
        following,
        postLikes,
        comments,
        reposts,
        sentGifts,
        receivedGifts,
        hostedAuctions,
        wonAuctions,
        reportsRecv,
        reportsMade,
        notifications,
        fiatPurchases,
      ];
}

class UserReportListItemEntity extends Equatable {
  const UserReportListItemEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
    this.roles = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.totalLikes = 0,
    this.country,
    this.city,
    this.createdAt,
    this.walletBalanceCoins = 0,
    this.deviceCount = 0,
    this.counts = const UserReportCountsEntity(),
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;
  final List<String> roles;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int totalLikes;
  final String? country;
  final String? city;
  final DateTime? createdAt;
  final double walletBalanceCoins;
  final int deviceCount;
  final UserReportCountsEntity counts;

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        email,
        avatarUrl,
        isVerified,
        isBanned,
        roles,
        followerCount,
        followingCount,
        postCount,
        totalLikes,
        country,
        city,
        createdAt,
        walletBalanceCoins,
        deviceCount,
        counts,
      ];
}

class UserReportProfileEntity extends Equatable {
  const UserReportProfileEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.bio,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
    this.banReason,
    this.bannedUntil,
    this.roles = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.totalLikes = 0,
    this.country,
    this.city,
    this.language,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;
  final String? banReason;
  final DateTime? bannedUntil;
  final List<String> roles;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int totalLikes;
  final String? country;
  final String? city;
  final String? language;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        email,
        bio,
        avatarUrl,
        isVerified,
        isBanned,
        banReason,
        bannedUntil,
        roles,
        followerCount,
        followingCount,
        postCount,
        totalLikes,
        country,
        city,
        language,
        createdAt,
        updatedAt,
      ];
}

class UserReportWalletTransactionEntity extends Equatable {
  const UserReportWalletTransactionEntity({
    required this.id,
    required this.type,
    required this.action,
    required this.amountCoins,
    required this.balanceAfterCoins,
    this.reason,
    this.createdAt,
  });

  final String id;
  final String type;
  final String action;
  final double amountCoins;
  final double balanceAfterCoins;
  final String? reason;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, type, action, amountCoins, balanceAfterCoins, reason, createdAt];
}

class UserReportWalletEntity extends Equatable {
  const UserReportWalletEntity({
    required this.balanceCoins,
    this.recentTransactions = const [],
  });

  final double balanceCoins;
  final List<UserReportWalletTransactionEntity> recentTransactions;

  @override
  List<Object?> get props => [balanceCoins, recentTransactions];
}

class UserReportDeviceSummaryEntity extends Equatable {
  const UserReportDeviceSummaryEntity({
    required this.id,
    required this.deviceType,
    this.osVersion,
    this.appVersion,
    this.lastActiveIp,
    this.lastActiveAt,
  });

  final String id;
  final String deviceType;
  final String? osVersion;
  final String? appVersion;
  final String? lastActiveIp;
  final DateTime? lastActiveAt;

  @override
  List<Object?> get props =>
      [id, deviceType, osVersion, appVersion, lastActiveIp, lastActiveAt];
}

class UserReportDevicesSectionEntity extends Equatable {
  const UserReportDevicesSectionEntity({
    required this.total,
    this.recent = const [],
  });

  final int total;
  final List<UserReportDeviceSummaryEntity> recent;

  @override
  List<Object?> get props => [total, recent];
}

class UserReportPeriodActivityEntity extends Equatable {
  const UserReportPeriodActivityEntity({
    this.postsCreated = 0,
    this.commentsMade = 0,
    this.likesGiven = 0,
    this.repostsMade = 0,
    this.viewsOnPosts = 0,
    this.likesOnPosts = 0,
    this.commentsOnPosts = 0,
    this.newFollowers = 0,
    this.giftsSent = 0,
    this.giftsReceived = 0,
    this.giftRevenueCoins = 0,
    this.auctionsHosted = 0,
    this.auctionsWon = 0,
  });

  final int postsCreated;
  final int commentsMade;
  final int likesGiven;
  final int repostsMade;
  final int viewsOnPosts;
  final int likesOnPosts;
  final int commentsOnPosts;
  final int newFollowers;
  final int giftsSent;
  final int giftsReceived;
  final double giftRevenueCoins;
  final int auctionsHosted;
  final int auctionsWon;

  @override
  List<Object?> get props => [
        postsCreated,
        commentsMade,
        likesGiven,
        repostsMade,
        viewsOnPosts,
        likesOnPosts,
        commentsOnPosts,
        newFollowers,
        giftsSent,
        giftsReceived,
        giftRevenueCoins,
        auctionsHosted,
        auctionsWon,
      ];
}

class UserReportPostMetricsEntity extends Equatable {
  const UserReportPostMetricsEntity({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.saves = 0,
    this.reposts = 0,
    this.shares = 0,
  });

  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int reposts;
  final int shares;

  @override
  List<Object?> get props => [views, likes, comments, saves, reposts, shares];
}

class UserReportNotificationsEntity extends Equatable {
  const UserReportNotificationsEntity({this.unreadCount = 0});

  final int unreadCount;

  @override
  List<Object?> get props => [unreadCount];
}

class UserReportDetailEntity extends Equatable {
  const UserReportDetailEntity({
    required this.period,
    required this.profile,
    required this.counts,
    required this.wallet,
    required this.devices,
    required this.periodActivity,
    required this.allTimePostMetrics,
    this.recentPosts = const [],
    this.topPostsInPeriod = const [],
    this.recentGiftsSent = const [],
    this.recentGiftsReceived = const [],
    this.notifications = const UserReportNotificationsEntity(),
  });

  final UserReportPeriod period;
  final UserReportProfileEntity profile;
  final UserReportCountsEntity counts;
  final UserReportWalletEntity wallet;
  final UserReportDevicesSectionEntity devices;
  final UserReportPeriodActivityEntity periodActivity;
  final UserReportPostMetricsEntity allTimePostMetrics;
  final List<UserPostEntity> recentPosts;
  final List<UserPostEntity> topPostsInPeriod;
  final List<UserGiftTransactionEntity> recentGiftsSent;
  final List<UserGiftTransactionEntity> recentGiftsReceived;
  final UserReportNotificationsEntity notifications;

  @override
  List<Object?> get props => [
        period,
        profile,
        counts,
        wallet,
        devices,
        periodActivity,
        allTimePostMetrics,
        recentPosts,
        topPostsInPeriod,
        recentGiftsSent,
        recentGiftsReceived,
        notifications,
      ];
}

enum UserReportSort {
  newest('NEWEST'),
  oldest('OLDEST'),
  mostFollowers('MOST_FOLLOWERS'),
  mostPosts('MOST_POSTS'),
  mostLikes('MOST_LIKES');

  const UserReportSort(this.apiValue);
  final String apiValue;
}

class UserReportListQuery extends Equatable {
  const UserReportListQuery({
    this.page = 1,
    this.limit = 20,
    this.search = '',
    this.isVerified,
    this.isBanned,
    this.role,
    this.sort = UserReportSort.newest,
  });

  final int page;
  final int limit;
  final String search;
  final bool? isVerified;
  final bool? isBanned;
  final String? role;
  final UserReportSort sort;

  UserReportListQuery copyWith({
    int? page,
    int? limit,
    String? search,
    bool? isVerified,
    bool? isBanned,
    String? role,
    UserReportSort? sort,
    bool clearVerified = false,
    bool clearBanned = false,
    bool clearRole = false,
  }) {
    return UserReportListQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      isVerified: clearVerified ? null : (isVerified ?? this.isVerified),
      isBanned: clearBanned ? null : (isBanned ?? this.isBanned),
      role: clearRole ? null : (role ?? this.role),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props =>
      [page, limit, search, isVerified, isBanned, role, sort];
}
