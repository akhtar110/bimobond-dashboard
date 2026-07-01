import 'dart:js_interop';

import 'api_config.dart';

@JS('localStorage.setItem')
external void _setItem(String key, String value);

@JS('window.location.reload')
external void _reload();

void saveHostedApiUrl(String apiBaseUrl, {String? socketBaseUrl}) {
  final url = ApiConfig.normalize(apiBaseUrl);
  _setItem('BIMO_API_BASE_URL', url);
  _setItem('BIMO_SOCKET_BASE_URL', ApiConfig.normalize(socketBaseUrl ?? url));
  _reload();
}

void reloadApp() => _reload();
