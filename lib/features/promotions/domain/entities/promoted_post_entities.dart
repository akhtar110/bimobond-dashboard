import 'package:equatable/equatable.dart';

import '../../../post_management/domain/entities/post_media_entity.dart';
import 'pagination_meta.dart';

class PromotedPostsQuery {
  const PromotedPostsQuery({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.search,
  });

  final int page;
  final int limit;
  final String? status;
  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status!.isNotEmpty) params['status'] = status;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    return params;
  }

  PromotedPostsQuery copyWith({
    int? page,
    int? limit,
    String? status,
    bool clearStatus = false,
    String? search,
    bool clearSearch = false,
  }) {
    return PromotedPostsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: clearStatus ? null : (status ?? this.status),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class PromotedPostSummaryEntity extends Equatable {
  const PromotedPostSummaryEntity({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.animatedCoverUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.repostCount = 0,
    this.isAd = false,
    this.status,
    this.userId,
    this.creatorUsername,
    this.creatorFullName,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? animatedCoverUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final int repostCount;
  final bool isAd;
  final String? status;
  final String? userId;
  final String? creatorUsername;
  final String? creatorFullName;

  /// Image URL for list/card previews (never a playable video file URL).
  String? get previewThumbnailUrl {
    for (final candidate in [thumbnailUrl, animatedCoverUrl]) {
      final url = candidate?.trim();
      if (url != null && url.isNotEmpty && !isLikelyVideoFileUrl(url)) {
        return url;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [id, description, thumbnailUrl, viewCount, likeCount];
}

class PostEngagementStatisticsEntity extends Equatable {
  const PostEngagementStatisticsEntity({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.reposts = 0,
    this.totalEngagements = 0,
    this.engagementRate = 0,
    this.promotedImpressions = 0,
    this.uniquePromotedViewers = 0,
    this.followersGained = 0,
    this.promotionSpendCoins = 0,
    this.costPerImpression = 0,
    this.costPerView = 0,
  });

  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int reposts;
  final int totalEngagements;
  final double engagementRate;
  final int promotedImpressions;
  final int uniquePromotedViewers;
  final int followersGained;
  final double promotionSpendCoins;
  final double costPerImpression;
  final double costPerView;

  @override
  List<Object?> get props => [views, likes, engagementRate, promotionSpendCoins];
}

class PostPromotionSummaryEntity extends Equatable {
  const PostPromotionSummaryEntity({
    this.totalCampaigns = 0,
    this.activeCampaigns = 0,
    this.totalImpressions = 0,
    this.totalSpentCoins = 0,
    this.totalBudgetCoins = 0,
    this.averageCostPerImpression = 0,
  });

  final int totalCampaigns;
  final int activeCampaigns;
  final int totalImpressions;
  final double totalSpentCoins;
  final double totalBudgetCoins;
  final double averageCostPerImpression;

  @override
  List<Object?> get props =>
      [totalCampaigns, activeCampaigns, totalImpressions, totalSpentCoins];
}

class CampaignProgressEntity extends Equatable {
  const CampaignProgressEntity({
    this.impressionCount = 0,
    this.impressionTarget = 0,
    this.remainingImpressions = 0,
    this.spentCoins = 0,
    this.budgetCoins = 0,
    this.remainingBudgetCoins = 0,
    this.progressPercent = 0,
    this.costPerImpression = 0,
  });

  final int impressionCount;
  final int impressionTarget;
  final int remainingImpressions;
  final double spentCoins;
  final double budgetCoins;
  final double remainingBudgetCoins;
  final double progressPercent;
  final double costPerImpression;

  @override
  List<Object?> get props => [impressionCount, impressionTarget, progressPercent];
}

class PrimaryCampaignEntity extends Equatable {
  const PrimaryCampaignEntity({
    required this.id,
    required this.status,
    required this.objective,
    this.budgetCoins = 0,
    this.spentCoins = 0,
    this.impressionCount = 0,
    this.impressionTarget = 0,
    this.progressPercent = 0,
    this.startAt,
    this.endAt,
    this.progress,
  });

  final String id;
  final String status;
  final String objective;
  final double budgetCoins;
  final double spentCoins;
  final int impressionCount;
  final int impressionTarget;
  final double progressPercent;
  final DateTime? startAt;
  final DateTime? endAt;
  final CampaignProgressEntity? progress;

  @override
  List<Object?> get props => [id, status, objective, progressPercent];
}

class CampaignHistoryItemEntity extends Equatable {
  const CampaignHistoryItemEntity({
    required this.id,
    required this.status,
    required this.objective,
    this.budgetCoins = 0,
    this.spentCoins = 0,
    this.impressionCount = 0,
    this.impressionTarget = 0,
    this.progressPercent = 0,
    this.startAt,
    this.endAt,
    this.progress,
    this.packageName,
  });

  final String id;
  final String status;
  final String objective;
  final double budgetCoins;
  final double spentCoins;
  final int impressionCount;
  final int impressionTarget;
  final double progressPercent;
  final DateTime? startAt;
  final DateTime? endAt;
  final CampaignProgressEntity? progress;
  final String? packageName;

  @override
  List<Object?> get props => [id, status, objective, progressPercent];
}

class ImpressionDayBucketEntity extends Equatable {
  const ImpressionDayBucketEntity({required this.date, required this.count});

  final String date;
  final int count;

  @override
  List<Object?> get props => [date, count];
}

class PromotionChartsEntity extends Equatable {
  const PromotionChartsEntity({
    this.impressionsLast7Days = const [],
    this.totalRecordedImpressions = 0,
    this.totalPromotionCostCoins = 0,
  });

  final List<ImpressionDayBucketEntity> impressionsLast7Days;
  final int totalRecordedImpressions;
  final double totalPromotionCostCoins;

  @override
  List<Object?> get props => [impressionsLast7Days, totalRecordedImpressions];
}

class PromotedPostEntity extends Equatable {
  const PromotedPostEntity({
    required this.post,
    required this.statistics,
    required this.promotion,
    this.primaryCampaign,
    this.campaigns = const [],
  });

  final PromotedPostSummaryEntity post;
  final PostEngagementStatisticsEntity statistics;
  final PostPromotionSummaryEntity promotion;
  final PrimaryCampaignEntity? primaryCampaign;
  final List<CampaignHistoryItemEntity> campaigns;

  @override
  List<Object?> get props => [post, statistics, promotion, primaryCampaign];
}

class PromotedPostDetailEntity extends Equatable {
  const PromotedPostDetailEntity({
    required this.post,
    required this.statistics,
    required this.promotion,
    this.primaryCampaign,
    this.campaigns = const [],
  });

  final PromotedPostSummaryEntity post;
  final PostEngagementStatisticsEntity statistics;
  final PostPromotionSummaryEntity promotion;
  final PrimaryCampaignEntity? primaryCampaign;
  final List<CampaignHistoryItemEntity> campaigns;

  @override
  List<Object?> get props => [post, promotion, campaigns];
}

class PostPromotionStatsEntity extends Equatable {
  const PostPromotionStatsEntity({
    required this.post,
    required this.statistics,
    required this.promotion,
    this.primaryCampaign,
    this.campaigns = const [],
    required this.charts,
  });

  final PromotedPostSummaryEntity post;
  final PostEngagementStatisticsEntity statistics;
  final PostPromotionSummaryEntity promotion;
  final PrimaryCampaignEntity? primaryCampaign;
  final List<CampaignHistoryItemEntity> campaigns;
  final PromotionChartsEntity charts;

  @override
  List<Object?> get props =>
      [post, statistics, promotion, primaryCampaign, charts];
}

class PromotedPostsPageEntity extends Equatable {
  const PromotedPostsPageEntity({
    required this.data,
    required this.meta,
  });

  final List<PromotedPostEntity> data;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [data, meta];
}
