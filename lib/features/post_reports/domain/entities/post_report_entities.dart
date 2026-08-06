import 'package:equatable/equatable.dart';

import '../../../post_management/domain/entities/managed_post_entity.dart';

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

class PostReportHashtag extends Equatable {
  const PostReportHashtag({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class PostReportCategory extends Equatable {
  const PostReportCategory({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String? iconUrl;

  @override
  List<Object?> get props => [id, name, iconUrl];
}

class PostReportCounts extends Equatable {
  const PostReportCounts({
    this.views = 0,
    this.postLikes = 0,
    this.comments = 0,
    this.saves = 0,
    this.reposts = 0,
    this.reports = 0,
    this.giftTransactions = 0,
    this.duets = 0,
  });

  final int views;
  final int postLikes;
  final int comments;
  final int saves;
  final int reposts;
  final int reports;
  final int giftTransactions;
  final int duets;

  @override
  List<Object?> get props =>
      [views, postLikes, comments, saves, reposts, reports, giftTransactions, duets];
}

class PostReportMetrics extends Equatable {
  const PostReportMetrics({
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.downloadCount = 0,
    this.engagementRate = 0,
    this.totalWatchTimeSeconds = 0,
    this.viewerRetentionRate = 0,
    this.completionRate = 0,
    this.trafficSourceBreakdown = const PostReportTrafficSourceBreakdown(),
  });

  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int repostCount;
  final int shareCount;
  final int downloadCount;
  final double engagementRate;
  final int totalWatchTimeSeconds;
  final double viewerRetentionRate;
  final double completionRate;
  final PostReportTrafficSourceBreakdown trafficSourceBreakdown;

  @override
  List<Object?> get props => [
        viewCount,
        likeCount,
        commentCount,
        saveCount,
        repostCount,
        shareCount,
        downloadCount,
        engagementRate,
        totalWatchTimeSeconds,
        viewerRetentionRate,
        completionRate,
        trafficSourceBreakdown,
      ];
}

class PostReportTrafficSourceBreakdown extends Equatable {
  const PostReportTrafficSourceBreakdown([this.bySource = const {}]);

  factory PostReportTrafficSourceBreakdown.fromMap(Map<dynamic, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return const PostReportTrafficSourceBreakdown();
    }
    final Map<String, int> map = {};
    raw.forEach((key, val) {
      if (key != null) {
        final canonical = normalizeKey(key.toString());
        int numVal = 0;
        if (val is num) {
          numVal = val.toInt();
        } else if (val is String) {
          numVal = int.tryParse(val) ?? 0;
        }
        if (numVal > 0) {
          map[canonical] = (map[canonical] ?? 0) + numVal;
        }
      }
    });
    return PostReportTrafficSourceBreakdown(map);
  }

  final Map<String, int> bySource;

  /// Normalizes legacy/alias source strings to canonical UPPER_SNAKE_CASE.
  static String normalizeKey(String key) {
    final trimmedUpper = key.trim().toUpperCase();
    return switch (trimmedUpper) {
      'HASHTAG' => 'HASHTAGS',
      'SHARE_LINK' || 'SHARE' || 'LINK' => 'SHARES',
      'AUDIO' || 'MUSIC' || 'TRACK' => 'SOUND',
      'LIVE_STREAM' || 'BROADCAST' => 'LIVE',
      'NOTIF' || 'PUSH' || 'PUSH_NOTIFICATION' => 'NOTIFICATION',
      'BOOKMARK' || 'BOOKMARKS' || 'SAVED_POSTS' => 'SAVED',
      'LIKES' || 'LIKED_POSTS' => 'LIKED',
      'REPOSTS' || 'SHARED_POST' => 'REPOST',
      'DM' || 'DIRECT' || 'DIRECT_MESSAGE' || 'MESSAGES' => 'CHAT',
      'DISCOVER' || 'EXPLORE_PAGE' => 'EXPLORE',
      'STORIES' || 'STORY_FEED' => 'STORY',
      'RECOMMENDATION' || 'SUGGESTED' || 'SUGGESTED_FOR_YOU' => 'RECOMMENDED',
      'AD' || 'ADS' || 'SPONSORED' || 'PROMOTED' => 'PROMOTION',
      'EXTERNAL_LINK' => 'EXTERNAL',
      '' => 'FOR_YOU',
      'FOR_YOU' ||
      'FOLLOWING' ||
      'PROFILE' ||
      'SEARCH' ||
      'HASHTAGS' ||
      'SHARES' ||
      'SOUND' ||
      'LIVE' ||
      'NOTIFICATION' ||
      'SAVED' ||
      'LIKED' ||
      'REPOST' ||
      'CHAT' ||
      'EXPLORE' ||
      'STORY' ||
      'RECOMMENDED' ||
      'PROMOTION' ||
      'EXTERNAL' =>
        trimmedUpper,
      _ => 'OTHER',
    };
  }

  int valueFor(String key) => bySource[normalizeKey(key)] ?? 0;

  int get forYou => valueFor('FOR_YOU');
  int get following => valueFor('FOLLOWING');
  int get profile => valueFor('PROFILE');
  int get search => valueFor('SEARCH');
  int get hashtags => valueFor('HASHTAGS');
  int get shares => valueFor('SHARES');
  int get sound => valueFor('SOUND');
  int get live => valueFor('LIVE');
  int get notification => valueFor('NOTIFICATION');
  int get saved => valueFor('SAVED');
  int get liked => valueFor('LIKED');
  int get repost => valueFor('REPOST');
  int get chat => valueFor('CHAT');
  int get other => valueFor('OTHER');

  int get total => bySource.values.fold(0, (sum, val) => sum + val);

  bool get isEmpty => bySource.isEmpty || total == 0;
  bool get isNotEmpty => !isEmpty;

  List<MapEntry<String, int>> get sortedEntries {
    final list = bySource.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    return list;
  }

  @override
  List<Object?> get props => [bySource];
}

class PostReportModerationLog extends Equatable {
  const PostReportModerationLog({
    required this.id,
    required this.status,
    required this.createdAt,
    this.reason,
    this.note,
    this.moderator,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String? reason;
  final String? note;
  final ReportAdminUser? moderator;

  @override
  List<Object?> get props => [id, status, createdAt, reason, note, moderator];
}

class PostReportModerationSummary extends Equatable {
  const PostReportModerationSummary({
    this.latestModerator,
    this.latestStatusChangeReason,
    this.latestActionDate,
    this.actionTimeline = const [],
  });

  final ReportAdminUser? latestModerator;
  final String? latestStatusChangeReason;
  final DateTime? latestActionDate;
  final List<PostReportModerationLog> actionTimeline;

  @override
  List<Object?> get props => [
        latestModerator,
        latestStatusChangeReason,
        latestActionDate,
        actionTimeline,
      ];
}

class PostReportPeriodActivity extends Equatable {
  const PostReportPeriodActivity({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.saves = 0,
    this.reposts = 0,
  });

  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int reposts;

  @override
  List<Object?> get props => [views, likes, comments, saves, reposts];
}

class PostReportRepost extends Equatable {
  const PostReportRepost({
    required this.id,
    required this.createdAt,
    this.quote,
    this.user,
  });

  final String id;
  final DateTime createdAt;
  final String? quote;
  final ReportAdminUser? user;

  @override
  List<Object?> get props => [id, createdAt, quote, user];
}

class PostReportComment extends Equatable {
  const PostReportComment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.user,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final ReportAdminUser? user;

  @override
  List<Object?> get props => [id, content, createdAt, likeCount, user];
}

class PostReportLike extends Equatable {
  const PostReportLike({
    required this.id,
    required this.createdAt,
    this.user,
  });

  final String id;
  final DateTime createdAt;
  final ReportAdminUser? user;

  @override
  List<Object?> get props => [id, createdAt, user];
}

class PostReportView extends Equatable {
  const PostReportView({
    required this.id,
    required this.createdAt,
    this.watchedDuration = 0,
    this.user,
  });

  final String id;
  final DateTime createdAt;
  final int watchedDuration;
  final ReportAdminUser? user;

  @override
  List<Object?> get props => [id, createdAt, watchedDuration, user];
}

class PostReportGiftSummary extends Equatable {
  const PostReportGiftSummary({
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

class PostReportGiftTransaction extends Equatable {
  const PostReportGiftTransaction({
    required this.id,
    required this.createdAt,
    this.priceCoins = 0,
    this.contributionCoins = 0,
    this.sender,
    this.receiver,
    this.gift,
  });

  final String id;
  final DateTime createdAt;
  final double priceCoins;
  final double contributionCoins;
  final ReportAdminUser? sender;
  final ReportAdminUser? receiver;
  final PostReportGiftSummary? gift;

  @override
  List<Object?> get props =>
      [id, createdAt, priceCoins, contributionCoins, sender, receiver, gift];
}

class PostReportModerationFlag extends Equatable {
  const PostReportModerationFlag({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporter,
  });

  final String id;
  final String reason;
  final String status;
  final DateTime createdAt;
  final ReportAdminUser? reporter;

  @override
  List<Object?> get props => [id, reason, status, createdAt, reporter];
}

class PostReportModerationFlags extends Equatable {
  const PostReportModerationFlags({
    this.total = 0,
    this.recent = const [],
  });

  final int total;
  final List<PostReportModerationFlag> recent;

  @override
  List<Object?> get props => [total, recent];
}

class PostReportListItem extends Equatable {
  const PostReportListItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.description,
    this.thumbnailUrl,
    this.animatedCoverUrl,
    this.videoUrl,
    this.media = const [],
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.isAd = false,
    this.isStory = false,
    this.isAuctionable = false,
    this.privacyStatus,
    this.user,
    this.hashtags = const [],
    this.categoryRelation,
    this.recentReposts = const [],
    this.counts = const PostReportCounts(),
  });

  final String id;
  final String userId;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? description;
  final String? thumbnailUrl;
  final String? animatedCoverUrl;
  final String? videoUrl;
  final List<PostMediaEntity> media;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int repostCount;
  final int shareCount;
  final bool isAd;
  final bool isStory;
  final bool isAuctionable;
  final String? privacyStatus;
  final ReportAdminUser? user;
  final List<PostReportHashtag> hashtags;
  final PostReportCategory? categoryRelation;
  final List<PostReportRepost> recentReposts;
  final PostReportCounts counts;

  /// First IMAGE in [media], otherwise [thumbnailUrl] — same as [ManagedPostEntity].
  String? get displayThumbnailUrl => resolvePostDisplayThumbnailUrl(
        media: media,
        thumbnailUrl: thumbnailUrl,
      );

  /// Image URL suitable for [CachedNetworkImage] (excludes video file URLs).
  String? get imagePreviewUrl {
    final thumb = displayThumbnailUrl;
    if (thumb != null && thumb.isNotEmpty && !isLikelyVideoFileUrl(thumb)) {
      return thumb;
    }
    return null;
  }

  /// Preview URL used in list/detail thumbnails (matches [PostCard] behavior).
  String? get previewMediaUrl {
    final image = imagePreviewUrl;
    if (image != null) return image;
    final video = videoUrl;
    if (video != null && video.isNotEmpty) return video;
    return null;
  }

  bool get needsAdminMediaLookup => imagePreviewUrl == null;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        status,
        createdAt,
        description,
        thumbnailUrl,
        animatedCoverUrl,
        videoUrl,
        media,
        viewCount,
        likeCount,
        commentCount,
        saveCount,
        repostCount,
        shareCount,
        isAd,
        isStory,
        isAuctionable,
        privacyStatus,
        user,
        hashtags,
        categoryRelation,
        recentReposts,
        counts,
      ];
}

class PostReportOverviewEntity extends Equatable {
  const PostReportOverviewEntity({
    required this.period,
    required this.totalPosts,
    required this.postsInPeriod,
    required this.published,
    required this.hidden,
    required this.stories,
    required this.ads,
    required this.auctionable,
    required this.byType,
    required this.byStatus,
    required this.periodEngagement,
    required this.topByViews,
    required this.topByLikes,
    required this.topByReposts,
  });

  final ReportPeriod period;
  final int totalPosts;
  final int postsInPeriod;
  final int published;
  final int hidden;
  final int stories;
  final int ads;
  final int auctionable;
  final List<ReportCountPair> byType;
  final List<ReportCountPair> byStatus;
  final PostReportPeriodActivity periodEngagement;
  final List<PostReportListItem> topByViews;
  final List<PostReportListItem> topByLikes;
  final List<PostReportListItem> topByReposts;

  @override
  List<Object?> get props => [
        period,
        totalPosts,
        postsInPeriod,
        published,
        hidden,
        stories,
        ads,
        auctionable,
        byType,
        byStatus,
        periodEngagement,
        topByViews,
        topByLikes,
        topByReposts,
      ];
}

class PostReportDetailEntity extends Equatable {
  const PostReportDetailEntity({
    required this.period,
    required this.post,
    required this.counts,
    required this.metrics,
    required this.periodActivity,
    required this.recentReposts,
    required this.recentComments,
    required this.recentLikes,
    required this.recentViews,
    required this.recentGifts,
    required this.moderationFlags,
    this.moderationSummary,
  });

  final ReportPeriod period;
  final PostReportListItem post;
  final PostReportCounts counts;
  final PostReportMetrics metrics;
  final PostReportPeriodActivity periodActivity;
  final List<PostReportRepost> recentReposts;
  final List<PostReportComment> recentComments;
  final List<PostReportLike> recentLikes;
  final List<PostReportView> recentViews;
  final List<PostReportGiftTransaction> recentGifts;
  final PostReportModerationFlags moderationFlags;
  final PostReportModerationSummary? moderationSummary;

  @override
  List<Object?> get props => [
        period,
        post,
        counts,
        metrics,
        periodActivity,
        recentReposts,
        recentComments,
        recentLikes,
        recentViews,
        recentGifts,
        moderationFlags,
        moderationSummary,
      ];
}
