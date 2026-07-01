import 'dart:convert';

/// Normalizes Dio response bodies across web/production edge cases.
abstract final class ApiResponseParser {
  static Map<String, dynamic> asMap(dynamic data) {
    final normalized = _normalize(data);
    if (normalized is Map<String, dynamic>) return normalized;
    if (normalized is Map) return Map<String, dynamic>.from(normalized);

    if (data is String) {
      final trimmed = data.trim();
      if (_looksLikeHtml(trimmed)) {
        throw FormatException(
          'Received HTML instead of JSON. If using ngrok, ensure the API URL is '
          'HTTPS and the backend allows CORS from this site.',
        );
      }
    }

    throw FormatException(
      'Expected JSON object, got ${data.runtimeType}',
    );
  }

  /// Unwraps common API envelopes: `{ data: {...} }`, `{ result: {...} }`.
  static Map<String, dynamic> unwrapAuthPayload(dynamic data) {
    final map = asMap(data);

    final nestedKeys = ['data', 'result', 'payload', 'user'];
    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        if (_looksLikeUserPayload(nestedMap) || key == 'user') {
          return _mergeRoles(map, nestedMap);
        }
      }
    }

    return map;
  }

  static dynamic _normalize(dynamic data) {
    if (data is Map) return data;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      if (_looksLikeHtml(trimmed)) return trimmed;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return decoded;
      } on FormatException {
        return trimmed;
      }
    }
    return data;
  }

  static bool _looksLikeHtml(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('<!doctype html') ||
        lower.startsWith('<html') ||
        lower.contains('<head>') && lower.contains('<body');
  }

  static bool _looksLikeUserPayload(Map<String, dynamic> json) {
    return json.containsKey('id') ||
        json.containsKey('_id') ||
        json.containsKey('email') ||
        json.containsKey('username') ||
        json.containsKey('roles');
  }

  static Map<String, dynamic> _mergeRoles(
    Map<String, dynamic> outer,
    Map<String, dynamic> inner,
  ) {
    if (inner.containsKey('roles')) return inner;
    final roles = outer['roles'];
    if (roles != null) {
      return {...inner, 'roles': roles};
    }
    return inner;
  }
}
