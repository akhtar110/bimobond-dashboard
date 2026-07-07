const { onRequest } = require("firebase-functions/v2/https");

const BACKEND_URL = "http://134.209.2.225";

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
    invoker: "public",
  },
  async (req, res) => {
    const backend = BACKEND_URL.replace(/\/+$/, "");
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
        message: `Could not reach ${BACKEND_URL}. Check that the server is online.`,
        target,
      });
    }
  },
);
