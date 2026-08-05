import '../../../../core/utils/api_page_parser.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/post_report_entities.dart';
import 'post_report_json_parser.dart';

abstract final class PostReportModels {
  static PostReportOverviewEntity overviewFromJson(dynamic data) {
    final json = PostReportJsonParser.unwrap(data);
    final totals = PostReportJsonParser.section(json, 'totals');
    final topPosts = PostReportJsonParser.section(json, 'topPosts');

    List<PostReportListItem> parseTopList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => PostReportJsonParser.parseListItem(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    return PostReportOverviewEntity(
      period: PostReportJsonParser.parsePeriod(json),
      totalPosts: PostReportJsonParser.asInt(totals['totalPosts'] ?? totals['total']),
      postsInPeriod: PostReportJsonParser.asInt(
        totals['postsInPeriod'] ?? totals['inPeriod'],
      ),
      published: PostReportJsonParser.asInt(totals['published']),
      hidden: PostReportJsonParser.asInt(totals['hidden']),
      stories: PostReportJsonParser.asInt(totals['stories']),
      ads: PostReportJsonParser.asInt(totals['ads']),
      auctionable: PostReportJsonParser.asInt(totals['auctionable']),
      byType: PostReportJsonParser.countPairs(json['byType']),
      byStatus: PostReportJsonParser.countPairs(json['byStatus']),
      periodEngagement: PostReportJsonParser.parsePeriodActivity(
        json['periodEngagement'],
      ),
      topByViews: parseTopList(topPosts['byViews']),
      topByLikes: parseTopList(topPosts['byLikes']),
      topByReposts: parseTopList(topPosts['byReposts']),
    );
  }

  static PaginatedPage<PostReportListItem> pageFromJson(dynamic data) {
    final meta = ApiPageParser.extractMeta(data);
    final items = ApiPageParser.extractList(
      data,
      listKeys: const ['data', 'posts', 'items', 'results'],
    ).map(PostReportJsonParser.parseListItem).toList();

    final page = ApiPageParser.intMeta(meta, 'page', fallback: 1);
    final totalPages = ApiPageParser.intMeta(
      meta,
      'totalPages',
      fallback: ApiPageParser.intMeta(meta, 'lastPage', fallback: 1),
    );

    return PaginatedPage(
      items: items,
      page: page,
      lastPage: totalPages,
      total: ApiPageParser.intMeta(meta, 'total', fallback: items.length),
    );
  }

  static PostReportDetailEntity detailFromJson(dynamic data) {
    final json = PostReportJsonParser.unwrap(data);
    final postRaw = json['post'];
    final post = postRaw is Map
        ? PostReportJsonParser.parseListItem(Map<String, dynamic>.from(postRaw))
        : PostReportListItem(
            id: '',
            userId: '',
            type: '',
            status: '',
            createdAt: DateTime.now(),
          );

    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic> m) parser,
    ) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => parser(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PostReportDetailEntity(
      period: PostReportJsonParser.parsePeriod(json),
      post: post,
      counts: PostReportJsonParser.parseCounts(json['counts']),
      metrics: PostReportJsonParser.parseMetrics(json['metrics']),
      periodActivity: PostReportJsonParser.parsePeriodActivity(
        json['periodActivity'],
      ),
      recentReposts: parseList(
        json['recentReposts'],
        PostReportJsonParser.parseRepost,
      ),
      recentComments: parseList(
        json['recentComments'],
        PostReportJsonParser.parseComment,
      ),
      recentLikes: parseList(
        json['recentLikes'],
        PostReportJsonParser.parseLike,
      ),
      recentViews: parseList(
        json['recentViews'],
        PostReportJsonParser.parseView,
      ),
      recentGifts: parseList(
        json['recentGifts'],
        PostReportJsonParser.parseGiftTransaction,
      ),
      moderationFlags: PostReportJsonParser.parseModerationFlags(
        json['moderationFlags'],
      ),
      moderationSummary: PostReportJsonParser.parseModerationSummary(
        json['moderationSummary'],
      ),
    );
  }
}
