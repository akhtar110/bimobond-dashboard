const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");

/**
 * Public URL that Cloud Functions can reach.
 * For a LAN API (e.g. http://192.168.1.123:3000), expose it with ngrok or
 * Cloudflare Tunnel and set this to the HTTPS tunnel URL.
 *
 * Configure in functions/.env.bomibondapp:
 *   BACKEND_URL=https://your-tunnel-or-api.example.com
 */
const backendUrl = defineString("BACKEND_URL", {
  description:
    "Reachable HTTPS URL for the NestJS/Express API (ngrok/Cloudflare tunnel for LAN)",
  default: "http://192.168.1.123:3000",
});

const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "content-length",
  "host",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

exports.apiProxy = onRequest(
  {
    cors: true,
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (req, res) => {
    const backend = backendUrl.value().replace(/\/+$/, "");
    const incoming = new URL(req.url, `https://${req.headers.host}`);
    const pathname = incoming.pathname.replace(/^\/api/, "") || "/";
    const target = `${backend}${pathname}${incoming.search}`;

    const headers = {};
    for (const [key, value] of Object.entries(req.headers)) {
      if (HOP_BY_HOP_HEADERS.has(key.toLowerCase())) continue;
      if (value == null) continue;
      headers[key] = Array.isArray(value) ? value.join(", ") : value;
    }

    const init = {
      method: req.method,
      headers,
    };

    if (req.method !== "GET" && req.method !== "HEAD") {
      init.body =
        req.rawBody && req.rawBody.length > 0 ? req.rawBody : undefined;
    }

    try {
      const upstream = await fetch(target, init);
      res.status(upstream.status);

      upstream.headers.forEach((value, key) => {
        if (HOP_BY_HOP_HEADERS.has(key.toLowerCase())) return;
        res.setHeader(key, value);
      });

      const body = Buffer.from(await upstream.arrayBuffer());
      res.send(body);
    } catch (error) {
      console.error("API proxy failed", { target, error });
      res.status(502).json({
        error: "Bad Gateway",
        message:
          "Could not reach BACKEND_URL. Set a public HTTPS URL in functions/.env.bomibondapp (ngrok/Cloudflare tunnel for LAN APIs).",
        target,
      });
    }
  },
);
