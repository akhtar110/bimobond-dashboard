import 'package:flutter/foundation.dart';

import 'api_config_stub.dart'
    if (dart.library.js_interop) 'api_config_web.dart' as runtime;

/// Resolves the REST API base URL for Dio and media URL resolution.
abstract final class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Canonical backend URL (local dev, mobile, media URLs, sockets).
  static const productionApiUrl = 'http://134.209.2.225';

  static const hostedApiProxyPath = '/api';

  static const missingConfigMessage =
      'Backend API URL is not configured. '
      'Set API_BASE_URL via --dart-define=API_BASE_URL=$productionApiUrl';

  static bool requiresHostedApiSetup() => false;

  static bool isConfigured() => resolve().isNotEmpty;

  /// Firebase Hosting is HTTPS; browsers block direct HTTP calls to [productionApiUrl].
  /// REST calls go to same-origin `/api`, proxied server-side to [productionApiUrl].
  static bool get usesHostedApiProxy =>
      kIsWeb && Uri.base.scheme == 'https';

  static String get backendUrl {
    if (_fromEnv.isNotEmpty) {
      return normalize(_fromEnv);
    }
    return productionApiUrl;
  }

  static String resolve() {
    if (_fromEnv.isNotEmpty) {
      return normalize(_fromEnv);
    }

    if (usesHostedApiProxy) {
      return '${Uri.base.origin}$hostedApiProxyPath';
    }

    final stored = runtime.readWebStoredApiBaseUrl();
    if (stored != null) {
      return normalize(stored);
    }

    final runtimeApi = runtime.readWebRuntimeApiBaseUrl();
    if (runtimeApi != null && runtimeApi.isNotEmpty) {
      return normalize(runtimeApi);
    }

    return backendUrl;
  }

  /// Socket.IO must talk to the real backend host (not the `/api` REST prefix).
  static String resolveSocketBaseUrl() {
    if (_fromEnv.isNotEmpty) {
      return normalize(_fromEnv);
    }

    final storedSocket = runtime.readWebStoredSocketBaseUrl();
    if (storedSocket != null) {
      return normalize(storedSocket);
    }

    final runtimeSocket = runtime.readWebRuntimeSocketBaseUrl();
    if (runtimeSocket != null && runtimeSocket.isNotEmpty) {
      return normalize(runtimeSocket);
    }

    return backendUrl;
  }

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
