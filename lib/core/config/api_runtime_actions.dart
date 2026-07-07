import 'api_runtime_actions_stub.dart'
    if (dart.library.html) 'api_runtime_actions_web.dart' as impl;

void saveHostedApiUrl(String apiBaseUrl, {String? socketBaseUrl}) =>
    impl.saveHostedApiUrl(apiBaseUrl, socketBaseUrl: socketBaseUrl);

void reloadApp() => impl.reloadApp();
