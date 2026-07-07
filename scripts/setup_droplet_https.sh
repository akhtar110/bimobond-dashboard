#!/usr/bin/env bash
# Enable HTTPS on the droplet so Firebase Hosting can call the API (Spark plan, no Functions).
set -euo pipefail

DOMAIN="134-209-2-225.sslip.io"
EMAIL="${CERTBOT_EMAIL:-admin@example.com}"
APP_PORT="${APP_PORT:-3000}"

echo "Setting up HTTPS for ${DOMAIN} -> http://127.0.0.1:${APP_PORT}"

sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx

sudo mkdir -p /var/www/certbot

# Temporary HTTP-only config for certbot bootstrap
sudo tee /etc/nginx/sites-available/bimo-api-https >/dev/null <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/bimo-api-https /etc/nginx/sites-enabled/bimo-api-https
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

sudo certbot --nginx \
  -d "${DOMAIN}" \
  --non-interactive \
  --agree-tos \
  -m "${EMAIL}" \
  --redirect

echo ""
echo "Done. Test:"
echo "  curl -sI https://${DOMAIN}/"
echo ""
echo "Firebase dashboard will use: https://${DOMAIN}"
