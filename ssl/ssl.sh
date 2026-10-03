#!/usr/bin/env bash
#
# Put an app running on localhost:<port> behind Nginx with a free Let's Encrypt
# TLS certificate (Ubuntu/Debian).
#
# Usage:  sudo ./ssl.sh
#         sudo DOMAIN=app.example.com EMAIL=me@example.com APP_PORT=3000 ./ssl.sh
#
# Prerequisites:
#   - A DNS A/AAAA record for the domain pointing at this server.
#   - Ports 80 and 443 open in your firewall / cloud security group.
#
set -Eeuo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Please run as root (sudo $0)"

# --- Install dependencies (idempotent) --------------------------------------
if ! command -v nginx >/dev/null 2>&1; then
  apt-get update
  apt-get install -y nginx
fi
if ! command -v certbot >/dev/null 2>&1; then
  apt-get install -y certbot python3-certbot-nginx
fi

# --- Collect and VALIDATE input ---------------------------------------------
# Everything typed here ends up inside an Nginx config file, so we only accept
# strictly formatted values (prevents config injection and typos).
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"
APP_PORT="${APP_PORT:-}"
[[ -n "$DOMAIN" ]]   || read -r -p "Domain name (e.g. app.example.com): " DOMAIN
[[ -n "$EMAIL" ]]    || read -r -p "Email for Let's Encrypt expiry notices: " EMAIL
[[ -n "$APP_PORT" ]] || read -r -p "Local port your app listens on (e.g. 3000): " APP_PORT

[[ "$DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]] \
  || die "Invalid domain name: '$DOMAIN'"
[[ "$EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]] \
  || die "Invalid email: '$EMAIL'"
if ! [[ "$APP_PORT" =~ ^[0-9]+$ ]] || (( APP_PORT < 1 || APP_PORT > 65535 )); then
  die "Invalid port: '$APP_PORT'"
fi

SITES_AVAILABLE=/etc/nginx/sites-available
SITES_ENABLED=/etc/nginx/sites-enabled
CONFIG_FILE="${SITES_AVAILABLE}/${DOMAIN}.conf"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

[[ ! -e "$CONFIG_FILE" ]] || die "$CONFIG_FILE already exists; remove it first if you want to regenerate it."

# --- Obtain the certificate -------------------------------------------------
# "certonly" only fetches the certificate; it does not rewrite Nginx config.
# We write our own hardened config below.
if [[ -f "${CERT_DIR}/fullchain.pem" && -f "${CERT_DIR}/privkey.pem" ]]; then
  echo "Certificate for ${DOMAIN} already exists, skipping issuance."
else
  certbot certonly --nginx --non-interactive --agree-tos \
    -m "$EMAIL" -d "$DOMAIN"
fi

# --- Write the Nginx site config --------------------------------------------
# Quoted heredoc ('EOF') = no shell expansion, so Nginx variables like $host stay
# literal. Our own values are substituted afterwards with sed.
cat > "$CONFIG_FILE" <<'EOF'
# Redirect all plain HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name __DOMAIN__;
    return 301 https://$host$request_uri;
}

server {
    # "listen ... http2" works on all Nginx versions shipped by Ubuntu 22.04+.
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name __DOMAIN__;

    # --- TLS -----------------------------------------------------------------
    ssl_certificate     /etc/letsencrypt/live/__DOMAIN__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__DOMAIN__/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;          # TLS 1.0/1.1 are broken and disabled
    ssl_prefer_server_ciphers off;          # modern clients pick the best cipher
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # --- Security headers -----------------------------------------------------
    server_tokens off;   # hide the Nginx version
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    client_max_body_size 10m;

    location / {
        proxy_pass http://127.0.0.1:__APP_PORT__;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/__DOMAIN___access.log;
    error_log  /var/log/nginx/__DOMAIN___error.log;
}
EOF
sed -i -e "s/__DOMAIN__/${DOMAIN}/g" -e "s/__APP_PORT__/${APP_PORT}/g" "$CONFIG_FILE"

# $connection_upgrade is defined once, globally, for all sites.
UPGRADE_MAP=/etc/nginx/conf.d/connection_upgrade.conf
if [[ ! -f "$UPGRADE_MAP" ]]; then
  cat > "$UPGRADE_MAP" <<'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
EOF
fi

if [[ -L "${SITES_ENABLED}/default" ]]; then
  unlink "${SITES_ENABLED}/default"
  echo "Disabled the default Nginx site."
fi
ln -sf "$CONFIG_FILE" "${SITES_ENABLED}/${DOMAIN}.conf"

# --- Test and reload ------------------------------------------------------------
if nginx -t; then
  systemctl reload nginx
  echo "Done: https://${DOMAIN} now proxies to 127.0.0.1:${APP_PORT}"
  echo "Certificates auto-renew via the certbot systemd timer (check: systemctl list-timers | grep certbot)."
else
  rm -f "${SITES_ENABLED}/${DOMAIN}.conf"
  die "Nginx config test failed; site disabled. Inspect $CONFIG_FILE"
fi
