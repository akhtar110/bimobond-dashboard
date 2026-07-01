import '../../../../core/utils/api_page_parser.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/gift_report_entities.dart';

abstract final class GiftReportModels {
  static GiftReportPeriod parsePeriod(Map<String, dynamic> json) {
    final period = json['period'];
    if (period is Map<String, dynamic>) {
      return GiftReportPeriod(
        from: _date(period['from']) ?? DateTime.now(),
        to: _date(period['to']) ?? DateTime.now(),
      );
    }
    return GiftReportPeriod(from: DateTime.now(), to: DateTime.now());
  }

  static GiftReportOverviewEntity overviewFromJson(dynamic data) {
    final json = _unwrap(data);
    final totals = _section(json, 'totals');
    final periodEngagement = _section(json, 'periodEngagement');
    final topGifts = _section(json, 'topGifts');
    final topUsers = _section(json, 'topUsers');

    return GiftReportOverviewEntity(
      period: parsePeriod(json),
      totalGifts: _int(totals['totalGifts']),
      activeGifts: _int(totals['activeGifts']),
      inactiveGifts: _int(totals['inactiveGifts']),
      totalTransactions: _int(totals['totalTransactions']),
      transactionsInPeriod: _int(totals['transactionsInPeriod']),
      inventoryHeld: _int(totals['inventoryHeld']),
      allTimeSpendCoins: _double(totals['allTimeSpendCoins']),
      allTimeContributionCoins: _double(totals['allTimeContributionCoins']),
      allTimeCommissionCoins: _double(totals['allTimeCommissionCoins']),
      periodTransactions: _int(periodEngagement['transactions']),
      periodSpendCoins: _double(periodEngagement['spendCoins']),
      periodContributionCoins: _double(periodEngagement['contributionCoins']),
      periodCommissionCoins: _double(periodEngagement['commissionCoins']),
      toPost: _int(periodEngagement['toPost']),
      toLive: _int(periodEngagement['toLive']),
      toAuction: _int(periodEngagement['toAuction']),
      direct: _int(periodEngagement['direct']),
      topGiftsBySends: _topGifts(topGifts['bySends']),
      topGiftsByRevenue: _topGifts(topGifts['byRevenue']),
      topSenders: _topSenders(topUsers['senders']),
      topReceivers: _topReceivers(topUsers['receivers']),
    );
  }

  static GiftReportListItemModel listItemFromJson(Map<String, dynamic> json) =>
      GiftReportListItemModel.fromJson(json);

  static GiftReportDetailEntity detailFromJson(dynamic data) {
    final json = _unwrap(data);
    final giftJson = json['gift'] as Map<String, dynamic>? ?? {};
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    final periodActivity =
        json['periodActivity'] as Map<String, dynamic>? ?? {};
    final context =
        json['contextBreakdown'] as Map<String, dynamic>? ?? {};

    final gift = listItemFromJson({
      ...giftJson,
      'counts': countsJson,
      'revenue': {
        'spendCoins': metrics['allTimeSpendCoins'],
        'contributionCoins': metrics['allTimeContributionCoins'],
      },
    });

    return GiftReportDetailEntity(
      period: parsePeriod(json),
      gift: gift,
      counts: _counts(countsJson),
      priceCoins: _double(metrics['priceCoins'] ?? gift.priceCoins),
      allTimeSpendCoins: _double(metrics['allTimeSpendCoins']),
      allTimeContributionCoins: _double(metrics['allTimeContributionCoins']),
      allTimeCommissionCoins: _double(metrics['allTimeCommissionCoins']),
      periodTransactions: _int(periodActivity['transactions']),
      periodSpendCoins: _double(periodActivity['spendCoins']),
      periodContributionCoins: _double(periodActivity['contributionCoins']),
      periodCommissionCoins: _double(periodActivity['commissionCoins']),
      toPost: _int(context['toPost']),
      toLive: _int(context['toLive']),
      toAuction: _int(context['toAuction']),
      direct: _int(context['direct']),
      recentTransactions: _transactions(json['recentTransactions']),
      topSenders: _topSenders(json['topSenders']),
      topReceivers: _topReceivers(json['topReceivers']),
    );
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {};
  }

  static Map<String, dynamic> _section(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    return value is Map<String, dynamic> ? value : {};
  }

  static GiftReportCounts _counts(Map<String, dynamic> json) {
    return GiftReportCounts(
      transactions: _int(json['transactions']),
      inventoryHolders: _int(json['inventoryHolders']),
      inventoryQuantity: _int(json['inventoryQuantity']),
    );
  }

  static GiftReportRevenue _revenue(Map<String, dynamic> json) {
    return GiftReportRevenue(
      spendCoins: _double(json['spendCoins']),
      contributionCoins: _double(json['contributionCoins']),
    );
  }

  static GiftReportUserSummary _userSummary(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const GiftReportUserSummary(id: '', username: '');
    }
    return GiftReportUserSummary(
      id: data['id']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      fullName: data['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(data['avatarUrl']?.toString()),
    );
  }

  static List<GiftReportTopGiftSummary> _topGifts(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(_topGiftFromJson).toList();
  }

  static GiftReportTopGiftSummary _topGiftFromJson(Map<String, dynamic> json) {
    final giftJson = json['gift'];
    final gift = giftJson is Map<String, dynamic> ? giftJson : null;

    return GiftReportTopGiftSummary(
      id: _firstString(json, const ['id', 'giftId']) ??
          _firstString(gift, const ['id']) ??
          '',
      name: _firstString(json, const ['name', 'giftName', 'title']) ??
          _firstString(gift, const ['name', 'title']) ??
          '',
      thumbnailUrl: resolveMediaUrl(
        _firstString(json, const ['thumbnailUrl', 'imageUrl']) ??
            _firstString(gift, const ['thumbnailUrl', 'imageUrl']),
      ),
      priceCoins: _double(
        json['priceCoins'] ??
            gift?['priceCoins'] ??
            json['price'] ??
            gift?['price'],
      ),
      transactions: _int(
        json['transactions'] ?? json['sendCount'] ?? json['count'],
      ),
      spendCoins: _double(
        json['spendCoins'] ??
            json['revenue'] ??
            json['totalSpendCoins'] ??
            json['grossCoins'],
      ),
    );
  }

  static String? _firstString(
    Map<String, dynamic>? json,
    List<String> keys,
  ) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static List<GiftReportTopUserActivity> _topSenders(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      final userJson = json['user'];
      return GiftReportTopUserActivity(
        user: _userSummary(userJson is Map<String, dynamic> ? userJson : json),
        sendCount: _int(json['sendCount']),
        spendCoins: _double(json['spendCoins']),
        contributionCoins: _double(json['contributionCoins']),
      );
    }).toList();
  }

  static List<GiftReportTopReceiverActivity> _topReceivers(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      final userJson = json['user'];
      return GiftReportTopReceiverActivity(
        user: _userSummary(userJson is Map<String, dynamic> ? userJson : json),
        receiveCount: _int(json['receiveCount']),
        earnedCoins: _double(json['earnedCoins']),
      );
    }).toList();
  }

  static List<GiftReportTransactionEntity> _transactions(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      final postJson = json['post'];
      return GiftReportTransactionEntity(
        id: json['id']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        receiverId: json['receiverId']?.toString() ?? '',
        giftId: json['giftId']?.toString() ?? '',
        postId: json['postId']?.toString(),
        liveId: json['liveId']?.toString(),
        auctionId: json['auctionId']?.toString(),
        priceCoins: _double(json['priceCoins']),
        contributionCoins: _double(json['contributionCoins']),
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        sender: json['sender'] != null ? _userSummary(json['sender']) : null,
        receiver:
            json['receiver'] != null ? _userSummary(json['receiver']) : null,
        post: postJson is Map<String, dynamic>
            ? GiftReportPostSummary(
                id: postJson['id']?.toString() ?? '',
                description: postJson['description']?.toString(),
                thumbnailUrl:
                    resolveMediaUrl(postJson['thumbnailUrl']?.toString()),
              )
            : null,
      );
    }).toList();
  }

  static int _int(dynamic v) => ApiPageParser.intVal(v);
  static double _double(dynamic v) => ApiPageParser.doubleVal(v);

  static DateTime? _date(dynamic v) {
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

class GiftReportListItemModel extends GiftReportListItemEntity {
  const GiftReportListItemModel({
    required super.id,
    required super.name,
    required super.thumbnailUrl,
    super.animationUrl,
    required super.priceCoins,
    required super.isActive,
    super.publishedAt,
    required super.counts,
    required super.revenue,
  });

  factory GiftReportListItemModel.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final revenueJson = json['revenue'] as Map<String, dynamic>? ?? {};

    return GiftReportListItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      thumbnailUrl:
          resolveMediaUrl(json['thumbnailUrl']?.toString()) ?? '',
      animationUrl: resolveMediaUrl(json['animationUrl']?.toString()),
      priceCoins: ApiPageParser.doubleVal(
        json['priceCoins'] ?? json['price'] ?? json['price_usd'],
      ),
      isActive: json['isActive'] as bool? ?? true,
      publishedAt: GiftReportModels._date(json['publishedAt']),
      counts: GiftReportModels._counts(countsJson),
      revenue: GiftReportModels._revenue(revenueJson),
    );
  }
}
