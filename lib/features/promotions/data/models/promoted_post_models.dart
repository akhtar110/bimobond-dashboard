import '../../../../core/utils/media_url_resolver.dart';
import '../../../post_management/domain/entities/post_media_entity.dart';
import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promoted_post_entities.dart';

double _double(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? readPromotionPostThumbnailUrl(Map<String, dynamic> json) {
  for (final key in [
    'thumbnailUrl',
    'thumbnail',
    'thumbUrl',
    'coverUrl',
    'posterUrl',
    'imageUrl',
  ]) {
    final resolved = resolveMediaUrl(json[key]?.toString());
    if (resolved != null &&
        resolved.isNotEmpty &&
        !isLikelyVideoFileUrl(resolved)) {
      return resolved;
    }
  }

  final video = json['video'];
  if (video is Map<String, dynamic>) {
    for (final key in ['thumbnailUrl', 'thumbnail', 'coverUrl', 'posterUrl']) {
      final resolved = resolveMediaUrl(video[key]?.toString());
      if (resolved != null &&
          resolved.isNotEmpty &&
          !isLikelyVideoFileUrl(resolved)) {
        return resolved;
      }
    }
  }

  return null;
}

String? readPromotionPostVideoUrl(Map<String, dynamic> json) {
  for (final key in ['videoUrl', 'url', 'src', 'path']) {
    final resolved = resolveMediaUrl(json[key]?.toString());
    if (resolved != null && resolved.isNotEmpty) return resolved;
  }

  final video = json['video'];
  if (video is Map<String, dynamic>) {
    for (final key in ['url', 'videoUrl', 'src', 'path']) {
      final resolved = resolveMediaUrl(video[key]?.toString());
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
  }

  return resolveMediaUrl(json['mediaUrl']?.toString());
}

class CampaignProgressModel extends CampaignProgressEntity {
  const CampaignProgressModel({
    super.impressionCount,
    super.impressionTarget,
    super.remainingImpressions,
    super.spentCoins,
    super.budgetCoins,
    super.remainingBudgetCoins,
    super.progressPercent,
    super.costPerImpression,
  });

  factory CampaignProgressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CampaignProgressModel();
    return CampaignProgressModel(
      impressionCount: _int(json['impressionCount']),
      impressionTarget: _int(json['impressionTarget']),
      remainingImpressions: _int(json['remainingImpressions']),
      spentCoins: _double(json['spentCoins']),
      budgetCoins: _double(json['budgetCoins']),
      remainingBudgetCoins: _double(json['remainingBudgetCoins']),
      progressPercent: _double(json['progressPercent']),
      costPerImpression: _double(json['costPerImpression']),
    );
  }
}

class PromotedPostSummaryModel extends PromotedPostSummaryEntity {
  const PromotedPostSummaryModel({
    required super.id,
    super.description,
    super.thumbnailUrl,
    super.videoUrl,
    super.animatedCoverUrl,
    super.viewCount,
    super.likeCount,
    super.commentCount,
    super.shareCount,
    super.saveCount,
    super.repostCount,
    super.isAd,
    super.status,
    super.userId,
    super.creatorUsername,
    super.creatorFullName,
  });

  factory PromotedPostSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PromotedPostSummaryModel(id: '');
    final user = json['user'] as Map<String, dynamic>?;
    return PromotedPostSummaryModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: readPromotionPostThumbnailUrl(json),
      videoUrl: readPromotionPostVideoUrl(json),
      animatedCoverUrl: resolveMediaUrl(json['animatedCoverUrl']?.toString()),
      viewCount: _int(json['viewCount'] ?? json['views']),
      likeCount: _int(json['likeCount'] ?? json['likes']),
      commentCount: _int(json['commentCount'] ?? json['comments']),
      shareCount: _int(json['shareCount'] ?? json['shares']),
      saveCount: _int(json['saveCount'] ?? json['saves']),
      repostCount: _int(json['repostCount'] ?? json['reposts']),
      isAd: json['isAd'] == true,
      status: json['status']?.toString(),
      userId: json['userId']?.toString() ?? user?['id']?.toString(),
      creatorUsername: user?['username']?.toString(),
      creatorFullName: user?['fullName']?.toString(),
    );
  }
}

class PostEngagementStatisticsModel extends PostEngagementStatisticsEntity {
  const PostEngagementStatisticsModel({
    super.views,
    super.likes,
    super.comments,
    super.shares,
    super.saves,
    super.reposts,
    super.totalEngagements,
    super.engagementRate,
    super.promotedImpressions,
    super.uniquePromotedViewers,
    super.followersGained,
    super.promotionSpendCoins,
    super.costPerImpression,
    super.costPerView,
  });

  factory PostEngagementStatisticsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PostEngagementStatisticsModel();
    return PostEngagementStatisticsModel(
      views: _int(json['views']),
      likes: _int(json['likes']),
      comments: _int(json['comments']),
      shares: _int(json['shares']),
      saves: _int(json['saves']),
      reposts: _int(json['reposts']),
      totalEngagements: _int(json['totalEngagements']),
      engagementRate: _double(json['engagementRate']),
      promotedImpressions: _int(json['promotedImpressions']),
      uniquePromotedViewers: _int(json['uniquePromotedViewers']),
      followersGained: _int(json['followersGained']),
      promotionSpendCoins: _double(json['promotionSpendCoins']),
      costPerImpression: _double(json['costPerImpression']),
      costPerView: _double(json['costPerView']),
    );
  }
}

class PostPromotionSummaryModel extends PostPromotionSummaryEntity {
  const PostPromotionSummaryModel({
    super.totalCampaigns,
    super.activeCampaigns,
    super.totalImpressions,
    super.totalSpentCoins,
    super.totalBudgetCoins,
    super.averageCostPerImpression,
  });

  factory PostPromotionSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PostPromotionSummaryModel();
    return PostPromotionSummaryModel(
      totalCampaigns: _int(json['totalCampaigns']),
      activeCampaigns: _int(json['activeCampaigns']),
      totalImpressions: _int(json['totalImpressions']),
      totalSpentCoins: _double(json['totalSpentCoins']),
      totalBudgetCoins: _double(json['totalBudgetCoins']),
      averageCostPerImpression: _double(json['averageCostPerImpression']),
    );
  }
}

class PrimaryCampaignModel extends PrimaryCampaignEntity {
  const PrimaryCampaignModel({
    required super.id,
    required super.status,
    required super.objective,
    super.budgetCoins,
    super.spentCoins,
    super.impressionCount,
    super.impressionTarget,
    super.progressPercent,
    super.startAt,
    super.endAt,
    super.progress,
  });

  factory PrimaryCampaignModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PrimaryCampaignModel(id: '', status: '', objective: '');
    }
    final progress = json['progress'] as Map<String, dynamic>?;
    return PrimaryCampaignModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      budgetCoins: _double(json['budgetCoins'] ?? progress?['budgetCoins']),
      spentCoins: _double(json['spentCoins'] ?? progress?['spentCoins']),
      impressionCount: _int(json['impressionCount'] ?? progress?['impressionCount']),
      impressionTarget: _int(json['impressionTarget'] ?? progress?['impressionTarget']),
      progressPercent: _double(json['progressPercent'] ?? progress?['progressPercent']),
      startAt: _date(json['startAt']),
      endAt: _date(json['endAt']),
      progress: progress != null ? CampaignProgressModel.fromJson(progress) : null,
    );
  }
}

class CampaignHistoryItemModel extends CampaignHistoryItemEntity {
  const CampaignHistoryItemModel({
    required super.id,
    required super.status,
    required super.objective,
    super.budgetCoins,
    super.spentCoins,
    super.impressionCount,
    super.impressionTarget,
    super.progressPercent,
    super.startAt,
    super.endAt,
    super.progress,
    super.packageName,
  });

  factory CampaignHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    final pkg = json['package'] as Map<String, dynamic>?;
    return CampaignHistoryItemModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      budgetCoins: _double(json['budgetCoins'] ?? progress?['budgetCoins']),
      spentCoins: _double(json['spentCoins'] ?? progress?['spentCoins']),
      impressionCount: _int(json['impressionCount'] ?? progress?['impressionCount']),
      impressionTarget: _int(json['impressionTarget'] ?? progress?['impressionTarget']),
      progressPercent: _double(json['progressPercent'] ?? progress?['progressPercent']),
      startAt: _date(json['startAt']),
      endAt: _date(json['endAt']),
      progress: progress != null ? CampaignProgressModel.fromJson(progress) : null,
      packageName: pkg?['name']?.toString() ?? json['packageName']?.toString(),
    );
  }
}

class ImpressionDayBucketModel extends ImpressionDayBucketEntity {
  const ImpressionDayBucketModel({required super.date, required super.count});

  factory ImpressionDayBucketModel.fromJson(Map<String, dynamic> json) {
    return ImpressionDayBucketModel(
      date: json['date']?.toString() ?? '',
      count: _int(json['count']),
    );
  }
}

class PromotionChartsModel extends PromotionChartsEntity {
  const PromotionChartsModel({
    super.impressionsLast7Days,
    super.totalRecordedImpressions,
    super.totalPromotionCostCoins,
  });

  factory PromotionChartsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PromotionChartsModel();
    final days = json['impressionsLast7Days'];
    return PromotionChartsModel(
      impressionsLast7Days: days is List
          ? days
              .map((e) => ImpressionDayBucketModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList()
          : const [],
      totalRecordedImpressions: _int(json['totalRecordedImpressions']),
      totalPromotionCostCoins: _double(json['totalPromotionCostCoins']),
    );
  }
}

class PromotedPostModel extends PromotedPostEntity {
  const PromotedPostModel({
    required super.post,
    required super.statistics,
    required super.promotion,
    super.primaryCampaign,
    super.campaigns,
  });

  factory PromotedPostModel.fromJson(Map<String, dynamic> json) {
    final campaigns = json['campaigns'];
    // Admin API returns owner at the row level; inject it into the post map
    // so PromotedPostSummaryModel can populate creator fields.
    final owner = json['owner'] as Map<String, dynamic>?;
    final rawPost = json['post'] as Map<String, dynamic>?;
    final postJson = (rawPost != null && owner != null)
        ? {...rawPost, 'user': rawPost['user'] ?? owner}
        : rawPost;
    return PromotedPostModel(
      post: PromotedPostSummaryModel.fromJson(postJson),
      statistics: PostEngagementStatisticsModel.fromJson(
        json['statistics'] as Map<String, dynamic>?,
      ),
      promotion: PostPromotionSummaryModel.fromJson(
        json['promotion'] as Map<String, dynamic>?,
      ),
      primaryCampaign: json['primaryCampaign'] != null
          ? PrimaryCampaignModel.fromJson(
              json['primaryCampaign'] as Map<String, dynamic>,
            )
          : null,
      campaigns: campaigns is List
          ? campaigns
              .map((e) => CampaignHistoryItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList()
          : const [],
    );
  }
}

class PromotedPostDetailModel extends PromotedPostDetailEntity {
  const PromotedPostDetailModel({
    required super.post,
    required super.statistics,
    required super.promotion,
    super.primaryCampaign,
    super.campaigns,
  });

  factory PromotedPostDetailModel.fromJson(Map<String, dynamic> json) {
    final campaigns = json['campaigns'];
    return PromotedPostDetailModel(
      post: PromotedPostSummaryModel.fromJson(
        json['post'] as Map<String, dynamic>?,
      ),
      statistics: PostEngagementStatisticsModel.fromJson(
        json['statistics'] as Map<String, dynamic>?,
      ),
      promotion: PostPromotionSummaryModel.fromJson(
        json['promotion'] as Map<String, dynamic>?,
      ),
      primaryCampaign: json['primaryCampaign'] != null
          ? PrimaryCampaignModel.fromJson(
              json['primaryCampaign'] as Map<String, dynamic>,
            )
          : null,
      campaigns: campaigns is List
          ? campaigns
              .map((e) => CampaignHistoryItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList()
          : const [],
    );
  }
}

class PostPromotionStatsModel extends PostPromotionStatsEntity {
  const PostPromotionStatsModel({
    required super.post,
    required super.statistics,
    required super.promotion,
    super.primaryCampaign,
    super.campaigns,
    required super.charts,
  });

  factory PostPromotionStatsModel.fromJson(Map<String, dynamic> json) {
    final campaigns = json['campaigns'];
    return PostPromotionStatsModel(
      post: PromotedPostSummaryModel.fromJson(
        json['post'] as Map<String, dynamic>?,
      ),
      statistics: PostEngagementStatisticsModel.fromJson(
        json['statistics'] as Map<String, dynamic>?,
      ),
      promotion: PostPromotionSummaryModel.fromJson(
        json['promotion'] as Map<String, dynamic>?,
      ),
      primaryCampaign: json['primaryCampaign'] != null
          ? PrimaryCampaignModel.fromJson(
              json['primaryCampaign'] as Map<String, dynamic>,
            )
          : null,
      campaigns: campaigns is List
          ? campaigns
              .map((e) => CampaignHistoryItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList()
          : const [],
      charts: PromotionChartsModel.fromJson(
        json['charts'] as Map<String, dynamic>?,
      ),
    );
  }
}

class PromotedPostsPageModel extends PromotedPostsPageEntity {
  const PromotedPostsPageModel({required super.data, required super.meta});

  factory PromotedPostsPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PromotedPostsPageModel(
      data: data is List
          ? data
              .map((e) => PromotedPostModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      meta: PaginationMeta(
        total: _int(meta['total']),
        page: _int(meta['page']),
        limit: _int(meta['limit']),
        totalPages: _int(meta['totalPages']),
      ),
    );
  }
}
