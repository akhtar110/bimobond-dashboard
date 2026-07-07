import 'dart:js_interop';

@JS('window.__BIMO_DASHBOARD_CONFIG__')
external BimoDashboardConfigJs? get _dashboardConfig;

extension type BimoDashboardConfigJs(JSObject _) implements JSObject {
  external String? get apiBaseUrl;
  external String? get socketBaseUrl;
}

String? _readUrl(String? Function(BimoDashboardConfigJs config) selector) {
  try {
    final config = _dashboardConfig;
    if (config == null) return null;
    final url = selector(config)?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  } on Object {
    return null;
  }
}

String? readWebRuntimeApiBaseUrl() =>
    _readUrl((config) => config.apiBaseUrl);

String? readWebRuntimeSocketBaseUrl() =>
    _readUrl((config) => config.socketBaseUrl);

String? readWebStoredApiBaseUrl() {
  try {
    final value =
        (localStorageGetItem('BIMO_API_BASE_URL') ?? '').trim();
    if (value.isEmpty) return null;
    return value;
  } on Object {
    return null;
  }
}

String? readWebStoredSocketBaseUrl() {
  try {
    final value =
        (localStorageGetItem('BIMO_SOCKET_BASE_URL') ?? '').trim();
    if (value.isEmpty) return null;
    return value;
  } on Object {
    return null;
  }
}

@JS('localStorage.getItem')
external String? localStorageGetItem(String key);
