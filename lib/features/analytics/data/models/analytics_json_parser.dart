import '../../domain/entities/analytics_entities.dart';

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
