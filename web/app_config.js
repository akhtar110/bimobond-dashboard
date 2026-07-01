// Runtime API configuration for the hosted dashboard.
//
// Always uses the LAN HTTP backend (never https for 192.168.x.x).
(function () {
  const LAN_API_BASE = 'http://192.168.1.123:3000';

  const readStorage = (key) => {
    try {
      return (localStorage.getItem(key) || '').trim();
    } catch (e) {
      return '';
    }
  };

  const isLocalApiHost = (hostname) => {
    const lower = hostname.toLowerCase();
    if (lower === 'localhost' || lower === '127.0.0.1' || lower === '0.0.0.0') {
      return true;
    }
    if (lower === '192.168.1.123') return true;
    return /^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(lower);
  };

  const scrubStaleHttpsLanUrls = () => {
    for (const key of ['BIMO_API_BASE_URL', 'BIMO_SOCKET_BASE_URL']) {
      const raw = readStorage(key);
      if (!raw) continue;
      try {
        const parsed = new URL(raw);
        if (isLocalApiHost(parsed.hostname) && parsed.protocol === 'https:') {
          localStorage.removeItem(key);
        }
      } catch (e) {
        localStorage.removeItem(key);
      }
    }
  };

  scrubStaleHttpsLanUrls();

  window.__BIMO_DASHBOARD_CONFIG__ = {
    apiBaseUrl: LAN_API_BASE,
    socketBaseUrl: LAN_API_BASE,
  };
})();
