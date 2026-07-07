import 'package:flutter/foundation.dart';

/// Resolves the REST API base URL for Dio and media URL resolution.
abstract final class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Single backend URL for local dev, mobile, and Firebase proxy target.
  static const productionApiUrl = 'http://134.209.2.225';

  static const missingConfigMessage =
      'Backend API URL is not configured. '
      'Set API_BASE_URL via --dart-define=API_BASE_URL=$productionApiUrl';

  static const hostedApiProxyPath = '/api';

  static bool requiresHostedApiSetup() => false;

  static bool isConfigured() => resolve().isNotEmpty;

  /// Firebase Hosting is HTTPS; browsers block direct HTTP calls to [productionApiUrl].
  /// Requests go to same-origin `/api`, proxied server-side to [productionApiUrl].
  static bool get usesHostedApiProxy =>
      kIsWeb && Uri.base.scheme == 'https';

  static String get backendUrl {
    if (_fromEnv.isNotEmpty) {
      return normalize(_fromEnv);
    }
    return productionApiUrl;
  }

  static String resolve() {
    if (usesHostedApiProxy) {
      return '${Uri.base.origin}$hostedApiProxyPath';
    }
    return backendUrl;
  }

  static String resolveSocketBaseUrl() => backendUrl;

  static String normalize(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return productionApiUrl;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return trimmed;

    if (_isLoopbackHost(uri.host)) {
      return productionApiUrl;
    }

    return trimmed;
  }

  static bool _isLoopbackHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'localhost' ||
        lower == '127.0.0.1' ||
        lower == '0.0.0.0';
  }
}
