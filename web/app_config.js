// Canonical backend API for the admin dashboard.
(function () {
  const API_BASE = 'http://134.209.2.225';

  // On Firebase Hosting (HTTPS), Flutter uses same-origin /api (see api_config.dart).
  // Leave apiBaseUrl empty there so we do not override the /api proxy with HTTP.
  const isHostedHttps =
    window.location.protocol === 'https:' &&
    window.location.hostname !== '134.209.2.225';

  window.__BIMO_DASHBOARD_CONFIG__ = {
    apiBaseUrl: isHostedHttps ? '' : API_BASE,
    socketBaseUrl: API_BASE,
  };
})();
