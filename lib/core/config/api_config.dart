import 'package:flutter/foundation.dart';

/// Resolves the REST API base URL for Dio and media URL resolution.
abstract final class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');
  static const productionApiUrl = 'http://192.168.1.123:3000';
  static const _lanApiHost = '192.168.1.123';
  static const _lanApiPort = 3000;

  static const missingConfigMessage =
      'Backend API URL is not configured. '
      'Set API_BASE_URL via --dart-define or web/app_config.js.';

  static bool requiresHostedApiSetup() => kIsWeb && !isConfigured();

  static bool isConfigured() => resolve().isNotEmpty;

  /// REST API base (no trailing slash). Always HTTP for the LAN backend.
  static String resolve() {
    if (_fromEnv.isNotEmpty) {
      return _coerceLanEndpoint(normalize(_fromEnv));
    }
    return productionApiUrl;
  }

  /// Socket.IO must connect directly to the API host (not the /api proxy).
  static String resolveSocketBaseUrl() {
    if (_fromEnv.isNotEmpty) {
      return _coerceLanEndpoint(normalize(_fromEnv));
    }
    return productionApiUrl;
  }

  static String _coerceLanEndpoint(String url) {
    final normalized = normalize(url);
    if (normalized.isEmpty) return productionApiUrl;

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return productionApiUrl;

    if (_isLocalApiHost(uri.host)) {
      return productionApiUrl;
    }

    return normalized;
  }

  static String normalize(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return trimmed;

    if (_isLocalApiHost(uri.host)) {
      final port = uri.hasPort ? uri.port : _lanApiPort;
      return 'http://$_lanApiHost:$port';
    }

    final loopback = _rewriteLoopbackToLan(uri);
    if (loopback != null) return loopback;

    return trimmed;
  }

  /// Maps saved `localhost` / `127.0.0.1` API URLs to the LAN backend host.
  static String? _rewriteLoopbackToLan(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1') return null;
    final port = uri.hasPort ? uri.port : 80;
    if (port != _lanApiPort && port != 80) return null;
    return productionApiUrl;
  }

  static bool _isLocalApiHost(String host) {
    final lower = host.toLowerCase();
    if (lower == _lanApiHost) return true;
    if (lower == 'localhost' || lower == '127.0.0.1' || lower == '0.0.0.0') {
      return true;
    }
    return RegExp(r'^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(lower);
  }
}
