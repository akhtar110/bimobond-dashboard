import 'package:equatable/equatable.dart';

class ReportPeriod extends Equatable {
  const ReportPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class ReportPeriodQuery extends Equatable {
  const ReportPeriodQuery({
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

class ReportAdminUser extends Equatable {
  const ReportAdminUser({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return username;
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isVerified, isBanned];
}

class ReportCountPair extends Equatable {
  const ReportCountPair({required this.key, required this.count});

  final String key;
  final int count;

  @override
  List<Object?> get props => [key, count];
}

class AuctionReportPostSummary extends Equatable {
  const AuctionReportPostSummary({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.status,
    this.viewCount = 0,
    this.user,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? status;
  final int viewCount;
  final ReportAdminUser? user;

  @override
  List<Object?> get props =>
      [id, description, thumbnailUrl, videoUrl, status, viewCount, user];
}

class AuctionReportLiveSummary extends Equatable {
  const AuctionReportLiveSummary({
    required this.id,
    this.title,
    this.status,
  });

  final String id;
  final String? title;
  final String? status;

  @override
  List<Object?> get props => [id, title, status];
}

class AuctionReportCounts extends Equatable {
  const AuctionReportCounts({
    this.bids = 0,
    this.giftTransactions = 0,
  });

  final int bids;
  final int giftTransactions;

  @override
  List<Object?> get props => [bids, giftTransactions];
}

class AuctionReportMetrics extends Equatable {
  const AuctionReportMetrics({
    this.startingPriceCoins = 0,
    this.targetPriceCoins = 0,
    this.currentTotalCoins = 0,
    this.remainingCoins = 0,
    this.progressPercent = 0,
  });

  final double startingPriceCoins;
  final double targetPriceCoins;
  final double currentTotalCoins;
  final double remainingCoins;
  final int progressPercent;

  @override
  List<Object?> get props => [
        startingPriceCoins,
        targetPriceCoins,
        currentTotalCoins,
        remainingCoins,
        progressPercent,
      ];
}

class AuctionReportPeriodActivity extends Equatable {
  const AuctionReportPeriodActivity({
    this.bids = 0,
    this.gifts = 0,
    this.contributionCoins = 0,
    this.giftSpendCoins = 0,
  });

  final int bids;
  final int gifts;
  final double contributionCoins;
  final double giftSpendCoins;

  @override
  List<Object?> get props => [bids, gifts, contributionCoins, giftSpendCoins];
}

class AuctionReportBid extends Equatable {
  const AuctionReportBid({
    required this.id,
    required this.createdAt,
    this.amountCoins = 0,
    this.bidder,
  });

  final String id;
  final DateTime createdAt;
  final double amountCoins;
  final ReportAdminUser? bidder;

  @override
  List<Object?> get props => [id, createdAt, amountCoins, bidder];
}

class AuctionReportGiftSummary extends Equatable {
  const AuctionReportGiftSummary({
    required this.id,
    required this.name,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [id, name, thumbnailUrl];
}

class AuctionReportGiftTransaction extends Equatable {
  const AuctionReportGiftTransaction({
    required this.id,
    required this.createdAt,
    this.priceCoins = 0,
    this.contributionCoins = 0,
    this.sender,
    this.gift,
  });

  final String id;
  final DateTime createdAt;
  final double priceCoins;
  final double contributionCoins;
  final ReportAdminUser? sender;
  final AuctionReportGiftSummary? gift;

  @override
  List<Object?> get props =>
      [id, createdAt, priceCoins, contributionCoins, sender, gift];
}

class AuctionReportContributor extends Equatable {
  const AuctionReportContributor({
    required this.user,
    this.giftCount = 0,
    this.totalContributionCoins = 0,
    this.totalSpendCoins = 0,
  });

  final ReportAdminUser user;
  final int giftCount;
  final double totalContributionCoins;
  final double totalSpendCoins;

  @override
  List<Object?> get props =>
      [user, giftCount, totalContributionCoins, totalSpendCoins];
}

class AuctionReportListItem extends Equatable {
  const AuctionReportListItem({
    required this.id,
    required this.hostId,
    required this.itemName,
    required this.status,
    required this.startedAt,
    this.postId,
    this.liveId,
    this.itemImageUrl,
    this.startingPriceCoins = 0,
    this.targetPriceCoins = 0,
    this.currentTotalCoins = 0,
    this.winnerId,
    this.endedAt,
    this.host,
    this.winner,
    this.post,
    this.live,
    this.progressPercent = 0,
    this.counts = const AuctionReportCounts(),
  });

  final String id;
  final String hostId;
  final String itemName;
  final String status;
  final DateTime startedAt;
  final String? postId;
  final String? liveId;
  final String? itemImageUrl;
  final double startingPriceCoins;
  final double targetPriceCoins;
  final double currentTotalCoins;
  final String? winnerId;
  final DateTime? endedAt;
  final ReportAdminUser? host;
  final ReportAdminUser? winner;
  final AuctionReportPostSummary? post;
  final AuctionReportLiveSummary? live;
  final int progressPercent;
  final AuctionReportCounts counts;

  @override
  List<Object?> get props => [
        id,
        hostId,
        itemName,
        status,
        startedAt,
        postId,
        liveId,
        itemImageUrl,
        startingPriceCoins,
        targetPriceCoins,
        currentTotalCoins,
        winnerId,
        endedAt,
        host,
        winner,
        post,
        live,
        progressPercent,
        counts,
      ];
}

class AuctionReportOverviewEntity extends Equatable {
  const AuctionReportOverviewEntity({
    required this.period,
    required this.totalAuctions,
    required this.auctionsInPeriod,
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.banned,
    required this.totalRevenueCoins,
    required this.totalGiftSpendCoins,
    required this.byStatus,
    required this.periodEngagement,
    required this.topByTotal,
    required this.topByBids,
    required this.topByGifts,
  });

  final ReportPeriod period;
  final int totalAuctions;
  final int auctionsInPeriod;
  final int active;
  final int completed;
  final int cancelled;
  final int banned;
  final double totalRevenueCoins;
  final double totalGiftSpendCoins;
  final List<ReportCountPair> byStatus;
  final AuctionReportPeriodActivity periodEngagement;
  final List<AuctionReportListItem> topByTotal;
  final List<AuctionReportListItem> topByBids;
  final List<AuctionReportListItem> topByGifts;

  @override
  List<Object?> get props => [
        period,
        totalAuctions,
        auctionsInPeriod,
        active,
        completed,
        cancelled,
        banned,
        totalRevenueCoins,
        totalGiftSpendCoins,
        byStatus,
        periodEngagement,
        topByTotal,
        topByBids,
        topByGifts,
      ];
}

class AuctionReportDetailEntity extends Equatable {
  const AuctionReportDetailEntity({
    required this.period,
    required this.auction,
    required this.counts,
    required this.metrics,
    required this.periodActivity,
    required this.recentBids,
    required this.recentGifts,
    required this.topContributors,
  });

  final ReportPeriod period;
  final AuctionReportListItem auction;
  final AuctionReportCounts counts;
  final AuctionReportMetrics metrics;
  final AuctionReportPeriodActivity periodActivity;
  final List<AuctionReportBid> recentBids;
  final List<AuctionReportGiftTransaction> recentGifts;
  final List<AuctionReportContributor> topContributors;

  @override
  List<Object?> get props => [
        period,
        auction,
        counts,
        metrics,
        periodActivity,
        recentBids,
        recentGifts,
        topContributors,
      ];
}
