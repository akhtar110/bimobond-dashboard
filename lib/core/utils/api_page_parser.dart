/// Shared helpers for paginated admin API responses (`data` + `meta`).
class ApiPageParser {
  ApiPageParser._();

  static List<Map<String, dynamic>> extractList(
    dynamic data, {
    List<String> listKeys = const ['data', 'items', 'results'],
  }) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is! Map<String, dynamic>) return const [];

    for (final key in listKeys) {
      final raw = data[key];
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().toList();
      }
      if (raw is Map<String, dynamic>) {
        for (final nested in listKeys) {
          final nestedList = raw[nested];
          if (nestedList is List) {
            return nestedList.whereType<Map<String, dynamic>>().toList();
          }
        }
      }
    }
    return const [];
  }

  static Map<String, dynamic> extractMeta(dynamic data) {
    if (data is! Map<String, dynamic>) return const {};
    final meta = data['meta'];
    if (meta is Map<String, dynamic>) return meta;
    final pagination = data['pagination'];
    if (pagination is Map<String, dynamic>) return pagination;
    return const {};
  }

  static int intMeta(Map<String, dynamic> meta, String key, {int fallback = 0}) {
    final v = meta[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double doubleVal(dynamic v, {double fallback = 0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int intVal(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
