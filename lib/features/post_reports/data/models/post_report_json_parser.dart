import '../../../../core/utils/media_url_resolver.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_report_entities.dart';

abstract final class PostReportJsonParser {
  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException('Expected JSON object, got ${data.runtimeType}');
  }

  static Map<String, dynamic> unwrap(dynamic data) {
    final map = asMap(data);
    if (map['data'] is Map) return asMap(map['data']);
    return map;
  }

  static ReportPeriod parsePeriod(Map<String, dynamic> json) {
    final period = json['period'];
    if (period is Map) {
      final p = Map<String, dynamic>.from(period);
      return ReportPeriod(
        from: _parseDate(p['from']) ?? DateTime.now(),
        to: _parseDate(p['to']) ?? DateTime.now(),
      );
    }
    return ReportPeriod(
      from: _parseDate(json['from']) ?? DateTime.now(),
      to: _parseDate(json['to']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double asDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static bool asBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return fallback;
  }

  static String? asString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic> section(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<ReportCountPair> countPairs(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((raw) {
            final m = Map<String, dynamic>.from(raw);
            final key = asString(m['type']) ??
                asString(m['status']) ??
                asString(m['key']) ??
                '';
            return ReportCountPair(key: key, count: asInt(m['count']));
          })
          .where((p) => p.key.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      return value.entries
          .map((e) => ReportCountPair(key: e.key, count: asInt(e.value)))
          .toList();
    }
    return const [];
  }

  static ReportAdminUser? parseAdminUser(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    final username = asString(m['username']);
    if (id == null || username == null) return null;
    return ReportAdminUser(
      id: id,
      username: username,
      fullName: asString(m['fullName']),
      email: asString(m['email']),
      avatarUrl: asString(m['avatarUrl']),
      isVerified: asBool(m['isVerified']),
      isBanned: asBool(m['isBanned']),
    );
  }

  static PostReportHashtag? parseHashtag(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    final name = asString(m['name']);
    if (id == null || name == null) return null;
    return PostReportHashtag(id: id, name: name);
  }

  static PostReportCategory? parseCategory(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    final name = asString(m['name']);
    if (id == null || name == null) return null;
    return PostReportCategory(
      id: id,
      name: name,
      iconUrl: asString(m['iconUrl']),
    );
  }

  static PostReportCounts parseCounts(dynamic value) {
    if (value is! Map) return const PostReportCounts();
    final m = Map<String, dynamic>.from(value);
    return PostReportCounts(
      views: asInt(m['views'] ?? m['viewCount']),
      postLikes: asInt(m['postLikes'] ?? m['likes'] ?? m['likeCount']),
      comments: asInt(m['comments'] ?? m['commentCount']),
      saves: asInt(m['saves'] ?? m['saveCount']),
      reposts: asInt(m['reposts'] ?? m['repostCount']),
      reports: asInt(m['reports']),
      giftTransactions: asInt(m['giftTransactions']),
      duets: asInt(m['duets']),
    );
  }

  static PostReportMetrics parseMetrics(dynamic value) {
    if (value is! Map) return const PostReportMetrics();
    final m = Map<String, dynamic>.from(value);
    return PostReportMetrics(
      viewCount: asInt(m['viewCount'] ?? m['views']),
      likeCount: asInt(m['likeCount'] ?? m['likes']),
      commentCount: asInt(m['commentCount'] ?? m['comments']),
      saveCount: asInt(m['saveCount'] ?? m['saves']),
      repostCount: asInt(m['repostCount'] ?? m['reposts']),
      shareCount: asInt(m['shareCount'] ?? m['shares']),
      downloadCount: asInt(m['downloadCount'] ?? m['downloads']),
      engagementRate: asDouble(m['engagementRate']),
      totalWatchTimeSeconds:
          asInt(m['totalWatchTimeSeconds'] ?? m['watchTimeSeconds']),
      viewerRetentionRate: asDouble(m['viewerRetentionRate']),
      completionRate: asDouble(m['completionRate']),
      trafficSourceBreakdown: parseTrafficSourceBreakdown(
        m['trafficSourceBreakdown'],
      ),
    );
  }

  static PostReportTrafficSourceBreakdown parseTrafficSourceBreakdown(
    dynamic value,
  ) {
    if (value is! Map) return const PostReportTrafficSourceBreakdown();
    final m = Map<String, dynamic>.from(value);
    return PostReportTrafficSourceBreakdown(
      forYou: asInt(m['FOR_YOU'] ?? m['forYou']),
      profile: asInt(m['PROFILE'] ?? m['profile']),
      search: asInt(m['SEARCH'] ?? m['search']),
      hashtags: asInt(m['HASHTAGS'] ?? m['hashtags']),
      shares: asInt(m['SHARES'] ?? m['shares']),
    );
  }

  static PostReportModerationLog parseModerationLog(Map<String, dynamic> m) {
    final moderatorRaw = m['moderator'] ?? m['admin'] ?? m['user'];
    return PostReportModerationLog(
      id: asString(m['id']) ?? '',
      status: (asString(m['status']) ?? asString(m['action']) ?? '')
          .toUpperCase(),
      reason: asString(m['reason']),
      note: asString(m['note']) ?? asString(m['internalNote']),
      createdAt: _parseDate(m['createdAt'] ?? m['timestamp'] ?? m['actionDate']) ??
          DateTime.now(),
      moderator: parseAdminUser(moderatorRaw),
    );
  }

  static PostReportModerationSummary? parseModerationSummary(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final timelineRaw = m['actionTimeline'] ?? m['timeline'];
    final timeline = timelineRaw is List
        ? timelineRaw
            .whereType<Map>()
            .map((e) => parseModerationLog(Map<String, dynamic>.from(e)))
            .toList()
        : const <PostReportModerationLog>[];

    return PostReportModerationSummary(
      latestModerator: parseAdminUser(m['latestModerator']),
      latestStatusChangeReason: asString(m['latestStatusChangeReason']),
      latestActionDate: _parseDate(m['latestActionDate']),
      actionTimeline: timeline,
    );
  }

  static PostReportPeriodActivity parsePeriodActivity(dynamic value) {
    if (value is! Map) return const PostReportPeriodActivity();
    final m = Map<String, dynamic>.from(value);
    return PostReportPeriodActivity(
      views: asInt(m['views']),
      likes: asInt(m['likes']),
      comments: asInt(m['comments']),
      saves: asInt(m['saves']),
      reposts: asInt(m['reposts']),
    );
  }

  static PostReportRepost parseRepost(Map<String, dynamic> m) {
    return PostReportRepost(
      id: asString(m['id']) ?? '',
      quote: asString(m['quote']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      user: parseAdminUser(m['user']),
    );
  }

  static PostReportComment parseComment(Map<String, dynamic> m) {
    return PostReportComment(
      id: asString(m['id']) ?? '',
      content: asString(m['content']) ?? '',
      likeCount: asInt(m['likeCount']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      user: parseAdminUser(m['user']),
    );
  }

  static PostReportLike parseLike(Map<String, dynamic> m) {
    return PostReportLike(
      id: asString(m['id']) ?? '',
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      user: parseAdminUser(m['user']),
    );
  }

  static PostReportView parseView(Map<String, dynamic> m) {
    return PostReportView(
      id: asString(m['id']) ?? '',
      watchedDuration: asInt(m['watchedDuration']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      user: parseAdminUser(m['user']),
    );
  }

  static PostReportGiftSummary? parseGiftSummary(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    final name = asString(m['name']);
    if (id == null || name == null) return null;
    return PostReportGiftSummary(
      id: id,
      name: name,
      thumbnailUrl: asString(m['thumbnailUrl']),
    );
  }

  static PostReportGiftTransaction parseGiftTransaction(Map<String, dynamic> m) {
    return PostReportGiftTransaction(
      id: asString(m['id']) ?? '',
      priceCoins: asDouble(m['priceCoins']),
      contributionCoins: asDouble(m['contributionCoins']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      sender: parseAdminUser(m['sender']),
      receiver: parseAdminUser(m['receiver']),
      gift: parseGiftSummary(m['gift']),
    );
  }

  static PostReportModerationFlag parseModerationFlag(Map<String, dynamic> m) {
    return PostReportModerationFlag(
      id: asString(m['id']) ?? '',
      reason: asString(m['reason']) ?? '',
      status: asString(m['status']) ?? '',
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      reporter: parseAdminUser(m['reporter']),
    );
  }

  static PostReportModerationFlags parseModerationFlags(dynamic value) {
    if (value is! Map) return const PostReportModerationFlags();
    final m = Map<String, dynamic>.from(value);
    final recentRaw = m['recent'];
    final recent = recentRaw is List
        ? recentRaw
            .whereType<Map>()
            .map((e) => parseModerationFlag(Map<String, dynamic>.from(e)))
            .toList()
        : const <PostReportModerationFlag>[];
    return PostReportModerationFlags(
      total: asInt(m['total']),
      recent: recent,
    );
  }

  static PostReportListItem parseListItem(Map<String, dynamic> m) {
    final hashtagsRaw = m['hashtags'];
    final hashtags = hashtagsRaw is List
        ? hashtagsRaw
            .map(parseHashtag)
            .whereType<PostReportHashtag>()
            .toList()
        : const <PostReportHashtag>[];

    final repostsRaw = m['recentReposts'];
    final recentReposts = repostsRaw is List
        ? repostsRaw
            .whereType<Map>()
            .map((e) => parseRepost(Map<String, dynamic>.from(e)))
            .toList()
        : const <PostReportRepost>[];

    return PostReportListItem(
      id: asString(m['id']) ?? '',
      userId: asString(m['userId']) ?? '',
      type: asString(m['type']) ?? '',
      status: asString(m['status']) ?? '',
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      description: asString(m['description']),
      thumbnailUrl: resolveMediaUrl(asString(m['thumbnailUrl'])),
      animatedCoverUrl: resolveMediaUrl(asString(m['animatedCoverUrl'])),
      videoUrl: resolveMediaUrl(asString(m['videoUrl'])),
      media: PostMediaEntity.listFromJson(m['media']),
      viewCount: asInt(m['viewCount']),
      likeCount: asInt(m['likeCount']),
      commentCount: asInt(m['commentCount']),
      saveCount: asInt(m['saveCount']),
      repostCount: asInt(m['repostCount']),
      shareCount: asInt(m['shareCount']),
      isAd: asBool(m['isAd']),
      isStory: asBool(m['isStory']),
      isAuctionable: asBool(m['isAuctionable']),
      privacyStatus: asString(m['privacyStatus']),
      user: parseAdminUser(m['user']),
      hashtags: hashtags,
      categoryRelation: parseCategory(m['categoryRelation']),
      recentReposts: recentReposts,
      counts: parseCounts(m['counts']),
    );
  }
}
