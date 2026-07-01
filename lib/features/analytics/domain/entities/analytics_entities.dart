import 'package:equatable/equatable.dart';

import 'period_engagement_entity.dart';
import 'post_status_count_entity.dart';
import 'post_type_count_entity.dart';

export 'period_engagement_entity.dart';
export 'post_status_count_entity.dart';
export 'post_type_count_entity.dart';

/// Alias for API docs / repository naming.
typedef DailyCountEntity = DailyCount;
typedef AdminOverviewEntity = AnalyticsOverviewEntity;
typedef AdminGrowthEntity = AnalyticsGrowthEntity;
typedef AdminEngagementEntity = AnalyticsEngagementEntity;
typedef AdminReportsEntity = AnalyticsReportsEntity;
typedef AdminCategoriesEntity = AnalyticsCategoriesEntity;
typedef AdminAuctionsEntity = AnalyticsAuctionsEntity;
typedef AdminMonetizationEntity = AnalyticsMonetizationEntity;
class AnalyticsPeriod extends Equatable {
  const AnalyticsPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class DailyCount extends Equatable {
  const DailyCount({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  List<Object?> get props => [date, count];
}

class AnalyticsOverviewEntity extends Equatable {
  const AnalyticsOverviewEntity({
    required this.period,
    required this.usersTotal,
    required this.usersNewInPeriod,
    required this.usersBanned,
    required this.postsTotal,
    required this.postsNewInPeriod,
    required this.postsPublished,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
    required this.totalSaves,
    required this.totalReports,
    required this.pendingReports,
    required this.giftsInPeriod,
    required this.walletBalances,
    required this.activeAuctions,
  });

  final AnalyticsPeriod period;
  final int usersTotal;
  final int usersNewInPeriod;
  final int usersBanned;
  final int postsTotal;
  final int postsNewInPeriod;
  final int postsPublished;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalSaves;
  final int totalReports;
  final int pendingReports;
  final int giftsInPeriod;
  final double walletBalances;
  final int activeAuctions;

  @override
  List<Object?> get props => [
        period,
        usersTotal,
        usersNewInPeriod,
        usersBanned,
        postsTotal,
        postsNewInPeriod,
        postsPublished,
        totalViews,
        totalLikes,
        totalComments,
        totalSaves,
        totalReports,
        pendingReports,
        giftsInPeriod,
        walletBalances,
        activeAuctions,
      ];
}

class AnalyticsUsersEntity extends Equatable {
  const AnalyticsUsersEntity({
    required this.period,
    required this.total,
    required this.newInPeriod,
    required this.verified,
    required this.banned,
    required this.roleCounts,
    required this.dailyNewUsers,
  });

  final AnalyticsPeriod period;
  final int total;
  final int newInPeriod;
  final int verified;
  final int banned;
  final Map<String, int> roleCounts;
  final List<DailyCount> dailyNewUsers;

  @override
  List<Object?> get props =>
      [period, total, newInPeriod, verified, banned, roleCounts, dailyNewUsers];
}

class AnalyticsPostsEntity extends Equatable {
  const AnalyticsPostsEntity({
    required this.period,
    required this.total,
    required this.inPeriod,
    required this.published,
    required this.hidden,
    required this.banned,
    required this.expired,
    required this.stories,
    required this.storiesInPeriod,
    required this.ads,
    required this.auctionable,
    required this.byType,
    required this.byStatus,
    required this.byTypeInPeriod,
    required this.byStatusInPeriod,
    required this.periodEngagement,
    required this.dailyNewPosts,
  });

  final AnalyticsPeriod period;
  final int total;
  final int inPeriod;
  final int published;
  final int hidden;
  final int banned;
  final int expired;
  final int stories;
  final int storiesInPeriod;
  final int ads;
  final int auctionable;
  final List<PostTypeCountEntity> byType;
  final List<PostStatusCountEntity> byStatus;
  final List<PostTypeCountEntity> byTypeInPeriod;
  final List<PostStatusCountEntity> byStatusInPeriod;
  final PeriodEngagementEntity periodEngagement;
  final List<DailyCount> dailyNewPosts;

  int get typeTotal => byType.fold(0, (sum, item) => sum + item.count);
  int get typeInPeriodTotal =>
      byTypeInPeriod.fold(0, (sum, item) => sum + item.count);
  int get statusTotal => byStatus.fold(0, (sum, item) => sum + item.count);
  int get statusInPeriodTotal =>
      byStatusInPeriod.fold(0, (sum, item) => sum + item.count);

  @override
  List<Object?> get props => [
        period,
        total,
        inPeriod,
        published,
        hidden,
        banned,
        expired,
        stories,
        storiesInPeriod,
        ads,
        auctionable,
        byType,
        byStatus,
        byTypeInPeriod,
        byStatusInPeriod,
        periodEngagement,
        dailyNewPosts,
      ];
}

/// Admin posts analytics (June 2026 API).
typedef AdminPostsAnalyticsEntity = AnalyticsPostsEntity;

class AnalyticsEngagementEntity extends Equatable {
  const AnalyticsEngagementEntity({
    required this.period,
    required this.views,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.reposts,
    required this.allTimeViews,
    required this.allTimeLikes,
    required this.allTimeComments,
    required this.allTimeSaves,
    required this.allTimeReposts,
  });

  final AnalyticsPeriod period;
  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int reposts;
  final int allTimeViews;
  final int allTimeLikes;
  final int allTimeComments;
  final int allTimeSaves;
  final int allTimeReposts;

  @override
  List<Object?> get props => [
        period,
        views,
        likes,
        comments,
        saves,
        reposts,
        allTimeViews,
        allTimeLikes,
        allTimeComments,
        allTimeSaves,
        allTimeReposts,
      ];
}

class AnalyticsMonetizationEntity extends Equatable {
  const AnalyticsMonetizationEntity({
    required this.period,
    required this.giftTransactionCount,
    required this.giftGrossCoins,
    required this.giftContributionCoins,
    required this.fiatPurchaseCount,
    required this.completedPurchaseVolume,
    required this.withdrawalRequestsInPeriod,
    required this.pendingWithdrawals,
    required this.totalBalanceCoins,
    required this.accountingByType,
  });

  final AnalyticsPeriod period;
  final int giftTransactionCount;
  final double giftGrossCoins;
  final double giftContributionCoins;
  final int fiatPurchaseCount;
  final double completedPurchaseVolume;
  final int withdrawalRequestsInPeriod;
  final int pendingWithdrawals;
  final double totalBalanceCoins;
  final Map<String, double> accountingByType;

  @override
  List<Object?> get props => [
        period,
        giftTransactionCount,
        giftGrossCoins,
        giftContributionCoins,
        fiatPurchaseCount,
        completedPurchaseVolume,
        withdrawalRequestsInPeriod,
        pendingWithdrawals,
        totalBalanceCoins,
        accountingByType,
      ];
}

class AnalyticsAuctionsEntity extends Equatable {
  const AnalyticsAuctionsEntity({
    required this.period,
    required this.total,
    required this.startedInPeriod,
    required this.byStatus,
    required this.targetVolume,
    required this.raisedVolume,
    required this.startingVolume,
    required this.avgRaised,
  });

  final AnalyticsPeriod period;
  final int total;
  final int startedInPeriod;
  final Map<String, int> byStatus;
  final double targetVolume;
  final double raisedVolume;
  final double startingVolume;
  final double avgRaised;

  @override
  List<Object?> get props => [
        period,
        total,
        startedInPeriod,
        byStatus,
        targetVolume,
        raisedVolume,
        startingVolume,
        avgRaised,
      ];
}

class AnalyticsReportsEntity extends Equatable {
  const AnalyticsReportsEntity({
    required this.period,
    required this.total,
    required this.inPeriod,
    required this.postReports,
    required this.userReports,
    required this.commentReports,
    required this.byStatus,
  });

  final AnalyticsPeriod period;
  final int total;
  final int inPeriod;
  final int postReports;
  final int userReports;
  final int commentReports;
  final Map<String, int> byStatus;

  @override
  List<Object?> get props => [
        period,
        total,
        inPeriod,
        postReports,
        userReports,
        commentReports,
        byStatus,
      ];
}

class CategoryPostCount extends Equatable {
  const CategoryPostCount({
    required this.categoryId,
    required this.count,
    required this.name,
    required this.slug,
  });

  final String categoryId;
  final int count;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [categoryId, count, name, slug];
}

class AnalyticsCategoriesEntity extends Equatable {
  const AnalyticsCategoriesEntity({
    required this.period,
    required this.totalCategories,
    required this.activeCategories,
    required this.postsByCategory,
  });

  final AnalyticsPeriod period;
  final int totalCategories;
  final int activeCategories;
  final List<CategoryPostCount> postsByCategory;

  @override
  List<Object?> get props =>
      [period, totalCategories, activeCategories, postsByCategory];
}

class AnalyticsGrowthEntity extends Equatable {
  const AnalyticsGrowthEntity({
    required this.period,
    required this.newUsers,
    required this.newPosts,
    required this.giftTransactions,
  });

  final AnalyticsPeriod period;
  final List<DailyCount> newUsers;
  final List<DailyCount> newPosts;
  final List<DailyCount> giftTransactions;

  @override
  List<Object?> get props => [period, newUsers, newPosts, giftTransactions];
}

/// Query params shared across analytics endpoints.
class AnalyticsQuery extends Equatable {
  const AnalyticsQuery({
    this.from,
    this.to,
    this.days = 30,
  });

  final DateTime? from;
  final DateTime? to;
  final int days;

  Map<String, dynamic> toQueryParameters() {
    if (from != null) {
      return {
        'from': from!.toUtc().toIso8601String(),
        if (to != null) 'to': to!.toUtc().toIso8601String(),
      };
    }
    return {'days': days};
  }

  @override
  List<Object?> get props => [from, to, days];
}
