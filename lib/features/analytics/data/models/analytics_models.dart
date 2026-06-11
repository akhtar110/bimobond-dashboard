import '../../domain/entities/analytics_entities.dart';
import 'analytics_json_parser.dart';

abstract final class AnalyticsModels {
  static AnalyticsOverviewEntity overviewFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final period = AnalyticsJsonParser.parsePeriod(json);
    final users = AnalyticsJsonParser.section(json, 'users');
    final posts = AnalyticsJsonParser.section(json, 'posts');
    final engagement = AnalyticsJsonParser.section(json, 'engagement');
    final moderation = AnalyticsJsonParser.section(json, 'moderation');
    final monetization = AnalyticsJsonParser.section(json, 'monetization');

    return AnalyticsOverviewEntity(
      period: period,
      usersTotal: AnalyticsJsonParser.asInt(users['total']),
      usersNewInPeriod: AnalyticsJsonParser.asInt(
        users['newInPeriod'] ?? users['new'],
      ),
      usersBanned: AnalyticsJsonParser.asInt(users['banned']),
      postsTotal: AnalyticsJsonParser.asInt(posts['total']),
      postsNewInPeriod: AnalyticsJsonParser.asInt(
        posts['newInPeriod'] ?? posts['new'],
      ),
      postsPublished: AnalyticsJsonParser.asInt(posts['published']),
      totalViews: AnalyticsJsonParser.asInt(engagement['totalViews'] ?? engagement['views']),
      totalLikes: AnalyticsJsonParser.asInt(engagement['totalLikes'] ?? engagement['likes']),
      totalComments: AnalyticsJsonParser.asInt(
        engagement['totalComments'] ?? engagement['comments'],
      ),
      totalSaves: AnalyticsJsonParser.asInt(engagement['totalSaves'] ?? engagement['saves']),
      totalReports: AnalyticsJsonParser.asInt(moderation['totalReports'] ?? moderation['total']),
      pendingReports: AnalyticsJsonParser.asInt(moderation['pendingReports'] ?? moderation['pending']),
      giftsInPeriod: AnalyticsJsonParser.asInt(monetization['giftsInPeriod'] ?? monetization['gifts']),
      walletBalances: AnalyticsJsonParser.asDouble(
        monetization['walletBalances'] ?? monetization['totalWalletBalanceUsd'],
      ),
      activeAuctions: AnalyticsJsonParser.asInt(monetization['activeAuctions']),
    );
  }

  static AnalyticsUsersEntity usersFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final totals = AnalyticsJsonParser.section(json, 'totals');
    return AnalyticsUsersEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      total: AnalyticsJsonParser.asInt(totals['total']),
      newInPeriod: AnalyticsJsonParser.asInt(
        totals['newInPeriod'] ?? totals['new'],
      ),
      verified: AnalyticsJsonParser.asInt(totals['verified']),
      banned: AnalyticsJsonParser.asInt(totals['banned']),
      roleCounts: AnalyticsJsonParser.intMap(json['roleCounts']),
      dailyNewUsers: AnalyticsJsonParser.dailySeries(json['dailyNewUsers']),
    );
  }

  static AnalyticsPostsEntity postsFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final totals = AnalyticsJsonParser.section(json, 'totals');
    return AnalyticsPostsEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      total: AnalyticsJsonParser.asInt(totals['total']),
      inPeriod: AnalyticsJsonParser.asInt(totals['inPeriod'] ?? totals['newInPeriod']),
      stories: AnalyticsJsonParser.asInt(totals['stories']),
      ads: AnalyticsJsonParser.asInt(totals['ads']),
      auctionable: AnalyticsJsonParser.asInt(totals['auctionable']),
      byType: AnalyticsJsonParser.intMap(json['byType']),
      byStatus: AnalyticsJsonParser.intMap(json['byStatus']),
      dailyNewPosts: AnalyticsJsonParser.dailySeries(json['dailyNewPosts']),
    );
  }

  static AnalyticsEngagementEntity engagementFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final inPeriod = AnalyticsJsonParser.section(json, 'inPeriod');
    final allTime = AnalyticsJsonParser.section(json, 'allTimeOnPosts');
    return AnalyticsEngagementEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      views: AnalyticsJsonParser.asInt(inPeriod['views']),
      likes: AnalyticsJsonParser.asInt(inPeriod['likes']),
      comments: AnalyticsJsonParser.asInt(inPeriod['comments']),
      saves: AnalyticsJsonParser.asInt(inPeriod['saves']),
      reposts: AnalyticsJsonParser.asInt(inPeriod['reposts']),
      allTimeViews: AnalyticsJsonParser.asInt(allTime['views'] ?? allTime['totalViews']),
      allTimeLikes: AnalyticsJsonParser.asInt(allTime['likes'] ?? allTime['totalLikes']),
      allTimeComments: AnalyticsJsonParser.asInt(allTime['comments'] ?? allTime['totalComments']),
      allTimeSaves: AnalyticsJsonParser.asInt(allTime['saves'] ?? allTime['totalSaves']),
      allTimeReposts: AnalyticsJsonParser.asInt(allTime['reposts'] ?? allTime['totalReposts']),
    );
  }

  static AnalyticsMonetizationEntity monetizationFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final gifts = AnalyticsJsonParser.section(json, 'gifts');
    final fiat = AnalyticsJsonParser.section(json, 'fiatPurchases');
    final withdrawals = AnalyticsJsonParser.section(json, 'withdrawals');
    final wallets = AnalyticsJsonParser.section(json, 'wallets');
    return AnalyticsMonetizationEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      giftTransactionCount: AnalyticsJsonParser.asInt(
        gifts['transactionCount'] ?? gifts['count'],
      ),
      giftGrossUsd: AnalyticsJsonParser.asDouble(gifts['grossUsd'] ?? gifts['gross']),
      giftContributionUsd: AnalyticsJsonParser.asDouble(
        gifts['contributionUsd'] ?? gifts['contribution'],
      ),
      fiatPurchaseCount: AnalyticsJsonParser.asInt(fiat['count']),
      fiatCompletedVolumeUsd: AnalyticsJsonParser.asDouble(
        fiat['completedVolume'] ?? fiat['completedVolumeUsd'],
      ),
      withdrawalRequestsInPeriod: AnalyticsJsonParser.asInt(
        withdrawals['requestsInPeriod'] ?? withdrawals['count'],
      ),
      pendingWithdrawals: AnalyticsJsonParser.asInt(
        withdrawals['pendingCount'] ?? withdrawals['pending'],
      ),
      totalWalletBalanceUsd: AnalyticsJsonParser.asDouble(
        wallets['totalBalanceUsd'] ?? wallets['totalBalance'],
      ),
      accountingByType: AnalyticsJsonParser.doubleMap(json['accountingByType']),
    );
  }

  static AnalyticsAuctionsEntity auctionsFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final totals = AnalyticsJsonParser.section(json, 'totals');
    final volume = AnalyticsJsonParser.section(json, 'inPeriodVolume');
    return AnalyticsAuctionsEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      total: AnalyticsJsonParser.asInt(totals['total']),
      startedInPeriod: AnalyticsJsonParser.asInt(
        totals['startedInPeriod'] ?? totals['inPeriod'],
      ),
      byStatus: AnalyticsJsonParser.intMap(json['byStatus']),
      targetVolume: AnalyticsJsonParser.asDouble(volume['targetTotal'] ?? volume['targetVolume']),
      raisedVolume: AnalyticsJsonParser.asDouble(volume['raisedTotal'] ?? volume['raisedVolume']),
      startingVolume: AnalyticsJsonParser.asDouble(volume['startingTotal'] ?? volume['startingVolume']),
      avgRaised: AnalyticsJsonParser.asDouble(volume['avgRaised'] ?? volume['averageRaised']),
    );
  }

  static AnalyticsReportsEntity reportsFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final totals = AnalyticsJsonParser.section(json, 'totals');
    return AnalyticsReportsEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      total: AnalyticsJsonParser.asInt(totals['total']),
      inPeriod: AnalyticsJsonParser.asInt(totals['inPeriod']),
      postReports: AnalyticsJsonParser.asInt(totals['postReports']),
      userReports: AnalyticsJsonParser.asInt(totals['userReports']),
      commentReports: AnalyticsJsonParser.asInt(totals['commentReports']),
      byStatus: AnalyticsJsonParser.intMap(json['byStatus']),
    );
  }

  static AnalyticsCategoriesEntity categoriesFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final totals = AnalyticsJsonParser.section(json, 'totals');
    final rawList = json['postsByCategory'];
    final postsByCategory = <CategoryPostCount>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final category = m['category'];
        final catMap = category is Map ? Map<String, dynamic>.from(category) : m;
        postsByCategory.add(
          CategoryPostCount(
            categoryId: m['categoryId']?.toString() ?? catMap['id']?.toString() ?? '',
            count: AnalyticsJsonParser.asInt(m['count']),
            name: catMap['name']?.toString() ?? 'Unknown',
            slug: catMap['slug']?.toString() ?? '',
          ),
        );
      }
    }
    postsByCategory.sort((a, b) => b.count.compareTo(a.count));

    return AnalyticsCategoriesEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      totalCategories: AnalyticsJsonParser.asInt(
        totals['totalCategories'] ?? totals['total'],
      ),
      activeCategories: AnalyticsJsonParser.asInt(totals['activeCategories'] ?? totals['active']),
      postsByCategory: postsByCategory,
    );
  }

  static AnalyticsGrowthEntity growthFromJson(dynamic data) {
    final json = AnalyticsJsonParser.unwrap(data);
    final daily = json['daily'];
    final dailyMap = daily is Map ? Map<String, dynamic>.from(daily) : json;
    return AnalyticsGrowthEntity(
      period: AnalyticsJsonParser.parsePeriod(json),
      newUsers: AnalyticsJsonParser.dailySeries(dailyMap['newUsers']),
      newPosts: AnalyticsJsonParser.dailySeries(dailyMap['newPosts']),
      giftTransactions: AnalyticsJsonParser.dailySeries(dailyMap['giftTransactions']),
    );
  }
}
