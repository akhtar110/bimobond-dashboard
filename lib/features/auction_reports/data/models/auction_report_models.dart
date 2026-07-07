import '../../../../core/utils/api_page_parser.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/auction_report_entities.dart';
import 'auction_report_json_parser.dart';

abstract final class AuctionReportModels {
  static AuctionReportOverviewEntity overviewFromJson(dynamic data) {
    final json = AuctionReportJsonParser.unwrap(data);
    final totals = AuctionReportJsonParser.section(json, 'totals');
    final topAuctions = AuctionReportJsonParser.section(json, 'topAuctions');

    List<AuctionReportListItem> parseTopList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => AuctionReportJsonParser.parseListItem(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    return AuctionReportOverviewEntity(
      period: AuctionReportJsonParser.parsePeriod(json),
      totalAuctions: AuctionReportJsonParser.asInt(
        totals['totalAuctions'] ?? totals['total'],
      ),
      auctionsInPeriod: AuctionReportJsonParser.asInt(
        totals['auctionsInPeriod'] ?? totals['inPeriod'],
      ),
      active: AuctionReportJsonParser.asInt(totals['active']),
      completed: AuctionReportJsonParser.asInt(totals['completed']),
      cancelled: AuctionReportJsonParser.asInt(totals['cancelled']),
      banned: AuctionReportJsonParser.asInt(totals['banned']),
      totalRevenueCoins: AuctionReportJsonParser.asDouble(
        totals['totalRevenueCoins'],
      ),
      totalGiftSpendCoins: AuctionReportJsonParser.asDouble(
        totals['totalGiftSpendCoins'],
      ),
      byStatus: AuctionReportJsonParser.countPairs(json['byStatus']),
      periodEngagement: AuctionReportJsonParser.parsePeriodActivity(
        json['periodEngagement'],
      ),
      topByTotal: parseTopList(topAuctions['byTotal']),
      topByBids: parseTopList(topAuctions['byBids']),
      topByGifts: parseTopList(topAuctions['byGifts']),
    );
  }

  static PaginatedPage<AuctionReportListItem> pageFromJson(dynamic data) {
    final meta = ApiPageParser.extractMeta(data);
    final items = ApiPageParser.extractList(data)
        .map(AuctionReportJsonParser.parseListItem)
        .toList();

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

  static AuctionReportDetailEntity detailFromJson(dynamic data) {
    final json = AuctionReportJsonParser.unwrap(data);
    final auctionRaw = json['auction'];
    final auction = auctionRaw is Map
        ? AuctionReportJsonParser.parseListItem(
            Map<String, dynamic>.from(auctionRaw),
          )
        : AuctionReportListItem(
            id: '',
            hostId: '',
            itemName: '',
            status: '',
            startedAt: DateTime.now(),
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

    return AuctionReportDetailEntity(
      period: AuctionReportJsonParser.parsePeriod(json),
      auction: auction,
      counts: AuctionReportJsonParser.parseCounts(json['counts']),
      metrics: AuctionReportJsonParser.parseMetrics(json['metrics']),
      periodActivity: AuctionReportJsonParser.parsePeriodActivity(
        json['periodActivity'],
      ),
      recentBids: parseList(
        json['recentBids'],
        AuctionReportJsonParser.parseBid,
      ),
      recentGifts: parseList(
        json['recentGifts'],
        AuctionReportJsonParser.parseGiftTransaction,
      ),
      topContributors: parseList(
        json['topContributors'],
        AuctionReportJsonParser.parseContributor,
      ),
    );
  }
}
