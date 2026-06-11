import 'package:equatable/equatable.dart';

class GiftReportPeriod extends Equatable {
  const GiftReportPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class GiftReportPeriodQuery extends Equatable {
  const GiftReportPeriodQuery({
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

enum GiftReportsSort {
  newest,
  oldest,
  priceAsc,
  priceDesc,
  mostSent,
  mostRevenue,
  name;

  String get apiValue => switch (this) {
        GiftReportsSort.newest => 'NEWEST',
        GiftReportsSort.oldest => 'OLDEST',
        GiftReportsSort.priceAsc => 'PRICE_ASC',
        GiftReportsSort.priceDesc => 'PRICE_DESC',
        GiftReportsSort.mostSent => 'MOST_SENT',
        GiftReportsSort.mostRevenue => 'MOST_REVENUE',
        GiftReportsSort.name => 'NAME',
      };
}

class GiftReportsListQuery extends Equatable {
  const GiftReportsListQuery({
    this.search,
    this.isActive,
    this.sort = GiftReportsSort.newest,
  });

  final String? search;
  final bool? isActive;
  final GiftReportsSort sort;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (isActive != null) 'isActive': isActive,
      'sort': sort.apiValue,
    };
  }

  @override
  List<Object?> get props => [search, isActive, sort];
}

class GiftReportCounts extends Equatable {
  const GiftReportCounts({
    required this.transactions,
    required this.inventoryHolders,
    required this.inventoryQuantity,
  });

  final int transactions;
  final int inventoryHolders;
  final int inventoryQuantity;

  @override
  List<Object?> get props =>
      [transactions, inventoryHolders, inventoryQuantity];
}

class GiftReportRevenue extends Equatable {
  const GiftReportRevenue({
    required this.spendUsd,
    required this.contributionUsd,
  });

  final double spendUsd;
  final double contributionUsd;

  @override
  List<Object?> get props => [spendUsd, contributionUsd];
}

class GiftReportListItemEntity extends Equatable {
  const GiftReportListItemEntity({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.animationUrl,
    required this.priceUsd,
    required this.isActive,
    this.publishedAt,
    required this.counts,
    required this.revenue,
  });

  final String id;
  final String name;
  final String thumbnailUrl;
  final String? animationUrl;
  final double priceUsd;
  final bool isActive;
  final DateTime? publishedAt;
  final GiftReportCounts counts;
  final GiftReportRevenue revenue;

  @override
  List<Object?> get props => [
        id,
        name,
        thumbnailUrl,
        animationUrl,
        priceUsd,
        isActive,
        publishedAt,
        counts,
        revenue,
      ];
}

class GiftReportUserSummary extends Equatable {
  const GiftReportUserSummary({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : username;

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl];
}

class GiftReportTopGiftSummary extends Equatable {
  const GiftReportTopGiftSummary({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.priceUsd,
    required this.transactions,
    required this.spendUsd,
  });

  final String id;
  final String name;
  final String? thumbnailUrl;
  final double priceUsd;
  final int transactions;
  final double spendUsd;

  @override
  List<Object?> get props =>
      [id, name, thumbnailUrl, priceUsd, transactions, spendUsd];
}

class GiftReportTopUserActivity extends Equatable {
  const GiftReportTopUserActivity({
    required this.user,
    required this.sendCount,
    required this.spendUsd,
    required this.contributionUsd,
  });

  final GiftReportUserSummary user;
  final int sendCount;
  final double spendUsd;
  final double contributionUsd;

  @override
  List<Object?> get props => [user, sendCount, spendUsd, contributionUsd];
}

class GiftReportTopReceiverActivity extends Equatable {
  const GiftReportTopReceiverActivity({
    required this.user,
    required this.receiveCount,
    required this.earnedUsd,
  });

  final GiftReportUserSummary user;
  final int receiveCount;
  final double earnedUsd;

  @override
  List<Object?> get props => [user, receiveCount, earnedUsd];
}

class GiftReportOverviewEntity extends Equatable {
  const GiftReportOverviewEntity({
    required this.period,
    required this.totalGifts,
    required this.activeGifts,
    required this.inactiveGifts,
    required this.totalTransactions,
    required this.transactionsInPeriod,
    required this.inventoryHeld,
    required this.allTimeSpendUsd,
    required this.allTimeContributionUsd,
    required this.allTimeCommissionUsd,
    required this.periodTransactions,
    required this.periodSpendUsd,
    required this.periodContributionUsd,
    required this.periodCommissionUsd,
    required this.toPost,
    required this.toLive,
    required this.toAuction,
    required this.direct,
    required this.topGiftsBySends,
    required this.topGiftsByRevenue,
    required this.topSenders,
    required this.topReceivers,
  });

  final GiftReportPeriod period;
  final int totalGifts;
  final int activeGifts;
  final int inactiveGifts;
  final int totalTransactions;
  final int transactionsInPeriod;
  final int inventoryHeld;
  final double allTimeSpendUsd;
  final double allTimeContributionUsd;
  final double allTimeCommissionUsd;
  final int periodTransactions;
  final double periodSpendUsd;
  final double periodContributionUsd;
  final double periodCommissionUsd;
  final int toPost;
  final int toLive;
  final int toAuction;
  final int direct;
  final List<GiftReportTopGiftSummary> topGiftsBySends;
  final List<GiftReportTopGiftSummary> topGiftsByRevenue;
  final List<GiftReportTopUserActivity> topSenders;
  final List<GiftReportTopReceiverActivity> topReceivers;

  @override
  List<Object?> get props => [
        period,
        totalGifts,
        activeGifts,
        inactiveGifts,
        totalTransactions,
        transactionsInPeriod,
        inventoryHeld,
        allTimeSpendUsd,
        allTimeContributionUsd,
        allTimeCommissionUsd,
        periodTransactions,
        periodSpendUsd,
        periodContributionUsd,
        periodCommissionUsd,
        toPost,
        toLive,
        toAuction,
        direct,
        topGiftsBySends,
        topGiftsByRevenue,
        topSenders,
        topReceivers,
      ];
}

class GiftReportPostSummary extends Equatable {
  const GiftReportPostSummary({
    required this.id,
    this.description,
    this.thumbnailUrl,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [id, description, thumbnailUrl];
}

class GiftReportTransactionEntity extends Equatable {
  const GiftReportTransactionEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.giftId,
    this.postId,
    this.liveId,
    this.auctionId,
    required this.priceUsd,
    required this.contributionUsd,
    required this.createdAt,
    this.sender,
    this.receiver,
    this.post,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String giftId;
  final String? postId;
  final String? liveId;
  final String? auctionId;
  final double priceUsd;
  final double contributionUsd;
  final DateTime createdAt;
  final GiftReportUserSummary? sender;
  final GiftReportUserSummary? receiver;
  final GiftReportPostSummary? post;

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        giftId,
        postId,
        liveId,
        auctionId,
        priceUsd,
        contributionUsd,
        createdAt,
        sender,
        receiver,
        post,
      ];
}

class GiftReportDetailEntity extends Equatable {
  const GiftReportDetailEntity({
    required this.period,
    required this.gift,
    required this.counts,
    required this.priceUsd,
    required this.allTimeSpendUsd,
    required this.allTimeContributionUsd,
    required this.allTimeCommissionUsd,
    required this.periodTransactions,
    required this.periodSpendUsd,
    required this.periodContributionUsd,
    required this.periodCommissionUsd,
    required this.toPost,
    required this.toLive,
    required this.toAuction,
    required this.direct,
    required this.recentTransactions,
    required this.topSenders,
    required this.topReceivers,
  });

  final GiftReportPeriod period;
  final GiftReportListItemEntity gift;
  final GiftReportCounts counts;
  final double priceUsd;
  final double allTimeSpendUsd;
  final double allTimeContributionUsd;
  final double allTimeCommissionUsd;
  final int periodTransactions;
  final double periodSpendUsd;
  final double periodContributionUsd;
  final double periodCommissionUsd;
  final int toPost;
  final int toLive;
  final int toAuction;
  final int direct;
  final List<GiftReportTransactionEntity> recentTransactions;
  final List<GiftReportTopUserActivity> topSenders;
  final List<GiftReportTopReceiverActivity> topReceivers;

  @override
  List<Object?> get props => [
        period,
        gift,
        counts,
        priceUsd,
        allTimeSpendUsd,
        allTimeContributionUsd,
        allTimeCommissionUsd,
        periodTransactions,
        periodSpendUsd,
        periodContributionUsd,
        periodCommissionUsd,
        toPost,
        toLive,
        toAuction,
        direct,
        recentTransactions,
        topSenders,
        topReceivers,
      ];
}
