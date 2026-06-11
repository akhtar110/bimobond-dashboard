import '../../domain/entities/auction_report_entities.dart';

abstract final class AuctionReportJsonParser {
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
            final key = asString(m['status']) ??
                asString(m['key']) ??
                asString(m['type']) ??
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

  static AuctionReportPostSummary? parsePostSummary(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    if (id == null) return null;
    return AuctionReportPostSummary(
      id: id,
      description: asString(m['description']),
      thumbnailUrl: asString(m['thumbnailUrl']),
      videoUrl: asString(m['videoUrl']),
      status: asString(m['status']),
      viewCount: asInt(m['viewCount']),
      user: parseAdminUser(m['user']),
    );
  }

  static AuctionReportLiveSummary? parseLiveSummary(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    if (id == null) return null;
    return AuctionReportLiveSummary(
      id: id,
      title: asString(m['title']),
      status: asString(m['status']),
    );
  }

  static AuctionReportCounts parseCounts(dynamic value) {
    if (value is! Map) return const AuctionReportCounts();
    final m = Map<String, dynamic>.from(value);
    return AuctionReportCounts(
      bids: asInt(m['bids'] ?? m['bidCount']),
      giftTransactions: asInt(m['giftTransactions'] ?? m['giftCount']),
    );
  }

  static AuctionReportMetrics parseMetrics(dynamic value) {
    if (value is! Map) return const AuctionReportMetrics();
    final m = Map<String, dynamic>.from(value);
    return AuctionReportMetrics(
      startingPriceUsd: asDouble(m['startingPriceUsd']),
      targetPriceUsd: asDouble(m['targetPriceUsd']),
      currentTotalUsd: asDouble(m['currentTotalUsd']),
      remainingUsd: asDouble(m['remainingUsd']),
      progressPercent: asInt(m['progressPercent']),
    );
  }

  static AuctionReportPeriodActivity parsePeriodActivity(dynamic value) {
    if (value is! Map) return const AuctionReportPeriodActivity();
    final m = Map<String, dynamic>.from(value);
    return AuctionReportPeriodActivity(
      bids: asInt(m['bids']),
      gifts: asInt(m['gifts']),
      contributionUsd: asDouble(m['contributionUsd']),
      giftSpendUsd: asDouble(m['giftSpendUsd']),
    );
  }

  static AuctionReportBid parseBid(Map<String, dynamic> m) {
    return AuctionReportBid(
      id: asString(m['id']) ?? '',
      amountUsd: asDouble(m['amountUsd']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      bidder: parseAdminUser(m['bidder']),
    );
  }

  static AuctionReportGiftSummary? parseGiftSummary(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = asString(m['id']);
    final name = asString(m['name']);
    if (id == null || name == null) return null;
    return AuctionReportGiftSummary(
      id: id,
      name: name,
      thumbnailUrl: asString(m['thumbnailUrl']),
    );
  }

  static AuctionReportGiftTransaction parseGiftTransaction(
    Map<String, dynamic> m,
  ) {
    return AuctionReportGiftTransaction(
      id: asString(m['id']) ?? '',
      priceUsd: asDouble(m['priceUsd']),
      contributionUsd: asDouble(m['contributionUsd']),
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      sender: parseAdminUser(m['sender']),
      gift: parseGiftSummary(m['gift']),
    );
  }

  static AuctionReportContributor parseContributor(Map<String, dynamic> m) {
    final user = parseAdminUser(m['user']);
    return AuctionReportContributor(
      user: user ??
          const ReportAdminUser(id: '', username: 'unknown'),
      giftCount: asInt(m['giftCount']),
      totalContributionUsd: asDouble(m['totalContributionUsd']),
      totalSpendUsd: asDouble(m['totalSpendUsd']),
    );
  }

  static AuctionReportListItem parseListItem(Map<String, dynamic> m) {
    return AuctionReportListItem(
      id: asString(m['id']) ?? '',
      hostId: asString(m['hostId']) ?? '',
      itemName: asString(m['itemName']) ?? '',
      status: asString(m['status']) ?? '',
      startedAt: _parseDate(m['startedAt']) ?? DateTime.now(),
      postId: asString(m['postId']),
      liveId: asString(m['liveId']),
      itemImageUrl: asString(m['itemImageUrl']),
      startingPriceUsd: asDouble(m['startingPriceUsd']),
      targetPriceUsd: asDouble(m['targetPriceUsd']),
      currentTotalUsd: asDouble(m['currentTotalUsd']),
      winnerId: asString(m['winnerId']),
      endedAt: _parseDate(m['endedAt']),
      host: parseAdminUser(m['host']),
      winner: parseAdminUser(m['winner']),
      post: parsePostSummary(m['post']),
      live: parseLiveSummary(m['live']),
      progressPercent: asInt(m['progressPercent']),
      counts: parseCounts(m['counts']),
    );
  }
}
