import '../../domain/entities/analytics_entities.dart';
import '../../domain/entities/period_engagement_entity.dart';
import '../../domain/entities/post_status_count_entity.dart';
import '../../domain/entities/post_type_count_entity.dart';

/// Shared JSON parsing helpers for analytics API responses.
abstract final class AnalyticsJsonParser {
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

  static AnalyticsPeriod parsePeriod(Map<String, dynamic> json) {
    final period = json['period'];
    if (period is Map) {
      final p = Map<String, dynamic>.from(period);
      return AnalyticsPeriod(
        from: _parseDate(p['from']) ?? DateTime.now(),
        to: _parseDate(p['to']) ?? DateTime.now(),
      );
    }
    return AnalyticsPeriod(
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

  static Map<String, int> intMap(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (k, v) => MapEntry(k.toString(), asInt(v)),
    );
  }

  static List<PostTypeCountEntity> postTypeCounts(
    dynamic value, {
    List<String> knownTypes = PostTypeCountEntity.knownTypes,
  }) {
    final counts = <String, int>{for (final type in knownTypes) type: 0};

    if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final type = m['type']?.toString().toUpperCase() ?? '';
        if (type.isEmpty) continue;
        counts[type] = asInt(m['count']);
      }
    } else if (value is Map) {
      for (final entry in intMap(value).entries) {
        counts[entry.key.toUpperCase()] = entry.value;
      }
    }

    return knownTypes
        .map((type) => PostTypeCountEntity(type: type, count: counts[type] ?? 0))
        .toList(growable: false);
  }

  static List<PostStatusCountEntity> postStatusCounts(
    dynamic value, {
    List<String> knownStatuses = PostStatusCountEntity.knownStatuses,
  }) {
    final counts = <String, int>{for (final status in knownStatuses) status: 0};

    if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final status = m['status']?.toString().toUpperCase() ?? '';
        if (status.isEmpty) continue;
        counts[status] = asInt(m['count']);
      }
    } else if (value is Map) {
      for (final entry in intMap(value).entries) {
        counts[entry.key.toUpperCase()] = entry.value;
      }
    }

    return knownStatuses
        .map(
          (status) =>
              PostStatusCountEntity(status: status, count: counts[status] ?? 0),
        )
        .toList(growable: false);
  }

  static PeriodEngagementEntity periodEngagement(dynamic value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : const {};
    return PeriodEngagementEntity(
      views: asInt(map['views']),
      likes: asInt(map['likes']),
      comments: asInt(map['comments']),
      reposts: asInt(map['reposts']),
    );
  }

  static Map<String, double> doubleMap(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (k, v) => MapEntry(k.toString(), asDouble(v)),
    );
  }

  static List<DailyCount> dailySeries(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((raw) {
          final m = Map<String, dynamic>.from(raw);
          return DailyCount(
            date: _parseDate(m['date']) ?? DateTime.now(),
            count: asInt(m['count']),
          );
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static Map<String, dynamic> section(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }
}
